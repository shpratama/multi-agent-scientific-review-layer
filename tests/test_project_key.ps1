# Re-runnable test for PROTOCOL.md section 18 / 18.1 (project_key and the identity check).
#
# Extracts the first ```powershell block under "### 18.1" (the Compare-ProjectRoot function)
# from PROTOCOL.md and tests THAT, so the documented function and this test cannot drift apart.
# Pure string logic: no files, no ~/.claude access. Windows form (the function normalizes
# Windows and Git Bash path spellings); Linux/macOS: not tested.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tests\test_project_key.ps1
#   pwsh -NoProfile -File tests/test_project_key.ps1
#
# Exit code 0 = all assertions held; 1 = at least one did not.

$ErrorActionPreference = 'Stop'
$repo     = Split-Path -Parent $PSScriptRoot
$protocol = [IO.File]::ReadAllText((Join-Path $repo 'PROTOCOL.md'), [Text.Encoding]::UTF8)
$start    = $protocol.IndexOf('### 18.1 ')
if ($start -lt 0) { throw 'section "### 18.1" not found in PROTOCOL.md' }
$m = [regex]::Match($protocol.Substring($start), '(?s)```powershell\r?\n(.*?)\r?\n```')
if (-not $m.Success) { throw 'no ```powershell block found under section 18.1' }
. ([scriptblock]::Create($m.Groups[1].Value))      # defines Compare-ProjectRoot in this scope
if (-not (Get-Command Compare-ProjectRoot -ErrorAction SilentlyContinue)) { throw 'Compare-ProjectRoot was not defined by the 18.1 block' }

# The section 18 key rule, as stated in the prose: replace \ / : and space with '-'.
function Get-Sec18Key([string]$p) { $p -replace '[\\/: ]', '-' }

$failures = 0; $total = 0
function Assert-Equal($name, $actual, $expected) {
    $script:total++
    if ($actual -ceq $expected) { Write-Output ("PASS  {0}  ({1})" -f $name, $actual) }
    else { $script:failures++; Write-Output ("FAIL  {0}  (got '{1}', expected '{2}')" -f $name, $actual, $expected) }
}

Write-Output '--- section 18: the key transform is lossy (documented limitation, asserted so it cannot be forgotten) ---'
Assert-Equal 'two different paths, one key (space vs hyphen)' ((Get-Sec18Key 'D:\Foo Bar\baz') -ceq (Get-Sec18Key 'D:\Foo-Bar\baz')) $true
Assert-Equal 'two different paths, one key (hyphen/space swapped)' ((Get-Sec18Key 'D:\Lab 2024-10\data') -ceq (Get-Sec18Key 'D:\Lab-2024 10\data')) $true
Assert-Equal 'one directory, two keys by case alone' ((Get-Sec18Key 'D:\Study\codes') -ceq (Get-Sec18Key 'D:\study\codes')) $false
Assert-Equal 'worked example in the prose' (Get-Sec18Key 'D:\Foo Bar\baz') 'D--Foo-Bar-baz'

Write-Output '--- section 18.1: Compare-ProjectRoot ---'
Assert-Equal 'identical paths'                              (Compare-ProjectRoot 'D:\Foo Bar\baz' 'D:\Foo Bar\baz')    'SAME'
Assert-Equal 'trailing separator ignored'                   (Compare-ProjectRoot 'D:\Foo Bar\baz\' 'D:\Foo Bar\baz')   'SAME'
Assert-Equal 'Git Bash spelling of the same directory'      (Compare-ProjectRoot '/d/Foo Bar/baz' 'D:\Foo Bar\baz')    'SAME'
Assert-Equal 'drive-letter case is not a difference'        (Compare-ProjectRoot 'd:\Foo Bar\baz' 'D:\Foo Bar\baz')    'SAME'
Assert-Equal 'drive root, both spellings'                   (Compare-ProjectRoot '/d' 'D:\')                           'SAME'
Assert-Equal 'case-only difference in a folder name'        (Compare-ProjectRoot 'D:\Study\codes' 'D:\study\codes')    'CASE-ONLY-DIFFERENCE'
Assert-Equal 'case-only difference via the Git Bash form'   (Compare-ProjectRoot '/d/study/codes' 'D:\Study\codes')    'CASE-ONLY-DIFFERENCE'
Assert-Equal 'the lossy-key collision pair is DIFFERENT'    (Compare-ProjectRoot 'D:\Foo Bar\baz' 'D:\Foo-Bar\baz')    'DIFFERENT-PROJECT'
Assert-Equal 'second collision pair is DIFFERENT'           (Compare-ProjectRoot 'D:\Lab 2024-10\data' 'D:\Lab-2024 10\data') 'DIFFERENT-PROJECT'
Assert-Equal 'different drive'                              (Compare-ProjectRoot 'D:\Foo' 'E:\Foo')                    'DIFFERENT-PROJECT'
Assert-Equal 'a prefix is not the same project'             (Compare-ProjectRoot 'D:\Foo' 'D:\Foo\sub')                'DIFFERENT-PROJECT'

Write-Output ("{0} of {1} assertions passed" -f ($total - $failures), $total)
if ($failures -gt 0) { exit 1 } else { exit 0 }
