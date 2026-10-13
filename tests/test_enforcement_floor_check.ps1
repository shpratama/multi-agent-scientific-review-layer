# Re-runnable test for PROTOCOL.md section 0.1 (enforcement-floor check), PowerShell form.
#
# It extracts the first ```powershell block under "### 0.1" from PROTOCOL.md and runs
# THAT block, so the documented command and this test cannot silently drift apart.
# Each scenario runs in a fresh child process of the SAME host that runs this script
# (Windows PowerShell 5.1 or pwsh 7), against a fake home and project directory under the
# system temp directory. It never reads or writes your real ~/.claude.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tests\test_enforcement_floor_check.ps1
#   pwsh -NoProfile -File tests/test_enforcement_floor_check.ps1   # fills in the "PowerShell 7: not tested" gap
#
# Exit code 0 = every scenario behaved as expected; 1 = at least one did not.
# The documented PowerShell form uses backslash paths, so on non-Windows hosts this test
# is skipped (use the Bash test there).

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -eq 'Core' -and -not $IsWindows) {
    Write-Output 'SKIP: the documented PowerShell form is Windows-oriented (backslash paths); use test_enforcement_floor_check.sh on this OS.'
    exit 0
}

$repo     = Split-Path -Parent $PSScriptRoot
$protocol = [IO.File]::ReadAllText((Join-Path $repo 'PROTOCOL.md'), [Text.Encoding]::UTF8)
$start    = $protocol.IndexOf('### 0.1 ')
if ($start -lt 0) { throw 'section "### 0.1" not found in PROTOCOL.md' }
$m = [regex]::Match($protocol.Substring($start), '(?s)```powershell\r?\n(.*?)\r?\n```')
if (-not $m.Success) { throw 'no ```powershell block found under section 0.1' }
$block   = $m.Groups[1].Value
$hostExe = (Get-Process -Id $PID).Path
$root    = Join-Path ([IO.Path]::GetTempPath()) ('floorcheck-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null

$withHook = '{"hooks":{"PreToolUse":[{"matcher":"Bash|Edit|Write","hooks":[{"type":"command","command":"python C:/example/scientific-debug/hook_gate.py"}]}]}}'
$noHook   = '{"permissions":{"allow":["Bash(ls)"]}}'
$encodings = @{
    utf8    = (New-Object Text.UTF8Encoding($false))
    utf8bom = (New-Object Text.UTF8Encoding($true))
    utf16   = [Text.Encoding]::Unicode   # UTF-16LE with BOM (what `>` produces in Windows PowerShell 5.1)
}

# Keys: hs = home settings.json, hl = home settings.local.json, ps = project settings.json, pl = project settings.local.json
function New-Fixture {
    param([string]$Name, [string]$HookIn, [string[]]$Exist, [string]$Enc = 'utf8', [string]$HomeName = 'home', [switch]$ProjSettingsIsDir)
    $base = Join-Path $root $Name
    $h = Join-Path $base $HomeName
    $p = Join-Path $base 'proj'
    New-Item -ItemType Directory -Force -Path (Join-Path $h '.claude'), (Join-Path $p '.claude'), (Join-Path $p 'src') | Out-Null
    $paths = @{
        hs = (Join-Path $h '.claude\settings.json');       hl = (Join-Path $h '.claude\settings.local.json')
        ps = (Join-Path $p '.claude\settings.json');       pl = (Join-Path $p '.claude\settings.local.json')
    }
    foreach ($k in $Exist) {
        if ($k -eq 'ps' -and $ProjSettingsIsDir) { New-Item -ItemType Directory -Path $paths[$k] | Out-Null; continue }
        $text = if ($k -eq $HookIn) { $withHook } else { $noHook }
        [IO.File]::WriteAllText($paths[$k], $text, $encodings[$Enc])   # NB: PowerShell variable names are case-insensitive; $Enc != $encodings on purpose
    }
    @{ Home = $h; Proj = $p; Src = (Join-Path $p 'src') }
}

function Quote-Literal([string]$s) { "'" + $s.Replace("'", "''") + "'" }

function Invoke-Check($fx, [string]$Cwd) {
    $id = [guid]::NewGuid().ToString('N')
    $script  = Join-Path $root "run-$id.ps1"
    $errFile = Join-Path $root "err-$id.txt"
    $pre = '$env:USERPROFILE = ' + (Quote-Literal $fx.Home) + "`r`n" +
           '$ProjectRoot = '     + (Quote-Literal $fx.Proj) + "`r`n" +
           'Set-Location -LiteralPath ' + (Quote-Literal $Cwd) + "`r`n"
    [IO.File]::WriteAllText($script, $pre + $block + "`r`n", (New-Object Text.UTF8Encoding($true)))
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'   # native stderr must not become a terminating error here
    try { $out = & $hostExe -NoProfile -ExecutionPolicy Bypass -File $script 2> $errFile } finally { $ErrorActionPreference = $prev }
    $err = @()
    if (Test-Path -LiteralPath $errFile) { $err = @(Get-Content -LiteralPath $errFile | Where-Object { $_.Trim() }) }
    @{ Found = (@($out | Where-Object { "$_".Trim() }).Count -gt 0); StderrLines = $err.Count }
}

$all = 'hs', 'hl', 'ps', 'pl'
# Name, fixture, which dir the shell is in ('proj' or 'src'), expected "registration found?"
$scenarios = @(
    @{ N = 'hook in home; all four files exist';                   Fx = { New-Fixture s01 'hs' $all };                                          Cwd = 'proj'; Expect = $true  },
    @{ N = 'hook in home; ONLY home settings.json exists';         Fx = { New-Fixture s02 'hs' @('hs') };                                       Cwd = 'proj'; Expect = $true  },
    @{ N = 'hook in home; home settings.local.json absent';        Fx = { New-Fixture s03 'hs' @('hs', 'ps', 'pl') };                           Cwd = 'proj'; Expect = $true  },
    @{ N = 'hook in home; project settings.local.json absent';     Fx = { New-Fixture s04 'hs' @('hs', 'hl', 'ps') };                           Cwd = 'proj'; Expect = $true  },
    @{ N = 'NO hook; home settings.local.json absent';             Fx = { New-Fixture s05 'none' @('hs', 'ps', 'pl') };                         Cwd = 'proj'; Expect = $false },
    @{ N = 'NO hook; all four files exist';                        Fx = { New-Fixture s06 'none' $all };                                        Cwd = 'proj'; Expect = $false },
    @{ N = 'NO settings files exist at all';                       Fx = { New-Fixture s07 'none' @() };                                         Cwd = 'proj'; Expect = $false },
    @{ N = 'hook only in PROJECT settings.json; shell in subdir';  Fx = { New-Fixture s08 'ps' @('hs', 'ps') };                                 Cwd = 'src';  Expect = $true  },
    @{ N = 'hook only in PROJECT settings.local.json';             Fx = { New-Fixture s09 'pl' @('hs', 'pl') };                                 Cwd = 'proj'; Expect = $true  },
    @{ N = 'hook in home; UTF-8 BOM';                              Fx = { New-Fixture s10 'hs' @('hs', 'ps') 'utf8bom' };                       Cwd = 'proj'; Expect = $true  },
    @{ N = 'hook in home; UTF-16LE with BOM';                      Fx = { New-Fixture s11 'hs' @('hs', 'ps') 'utf16' };                         Cwd = 'proj'; Expect = $true  },
    @{ N = 'hook in home; project settings.json is a DIRECTORY';   Fx = { New-Fixture s12 'hs' @('hs', 'ps') 'utf8' 'home' -ProjSettingsIsDir };  Cwd = 'proj'; Expect = $true  },
    @{ N = 'hook in home; [ ] and spaces in the home path';        Fx = { New-Fixture s13 'hs' @('hs', 'ps') 'utf8' 'Jane [x] Doe' };          Cwd = 'proj'; Expect = $true  }
)

$failures = 0
try {
    Write-Output ("host: PowerShell {0} ({1}); documented block extracted from PROTOCOL.md section 0.1" -f $PSVersionTable.PSVersion, $PSVersionTable.PSEdition)
    foreach ($s in $scenarios) {
        $fx  = & $s.Fx
        $cwd = if ($s.Cwd -eq 'src') { $fx.Src } else { $fx.Proj }
        $r   = Invoke-Check $fx $cwd
        $ok  = ($r.Found -eq $s.Expect) -and ($r.StderrLines -eq 0)
        if (-not $ok) { $failures++ }
        Write-Output ("{0}  {1}  (found={2}, expected={3}, stderr_lines={4})" -f $(if ($ok) { 'PASS' } else { 'FAIL' }), $s.N, $r.Found, $s.Expect, $r.StderrLines)
    }
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Output ("{0} of {1} scenarios passed" -f ($scenarios.Count - $failures), $scenarios.Count)
if ($failures -gt 0) { exit 1 } else { exit 0 }
