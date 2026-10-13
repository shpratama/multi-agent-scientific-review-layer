# Re-runnable test for PROTOCOL.md section 10.1 (fingerprints), PowerShell recipe.
#
# Extracts the first ```powershell block under "### 10.1" (Get-Fingerprint) from PROTOCOL.md and
# tests THAT. Fixtures are generated in-script from exact bytes under the system temp directory.
# The expected digests below are the SAME literals used by tests/test_fingerprint_normalization.sh,
# so a pass in both shells means the two recipes agree with each other, not just with themselves.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tests\test_fingerprint_normalization.ps1
#   pwsh -NoProfile -File tests/test_fingerprint_normalization.ps1
#
# Exit code 0 = all assertions held; 1 = at least one did not.

$ErrorActionPreference = 'Stop'
$repo     = Split-Path -Parent $PSScriptRoot
$protocol = [IO.File]::ReadAllText((Join-Path $repo 'PROTOCOL.md'), [Text.Encoding]::UTF8)
$start    = $protocol.IndexOf('### 10.1 ')
if ($start -lt 0) { throw 'section "### 10.1" not found in PROTOCOL.md' }
$m = [regex]::Match($protocol.Substring($start), '(?s)```powershell\r?\n(.*?)\r?\n```')
if (-not $m.Success) { throw 'no ```powershell block found under section 10.1' }
. ([scriptblock]::Create($m.Groups[1].Value))      # defines Get-Fingerprint in this scope
if (-not (Get-Command Get-Fingerprint -ErrorAction SilentlyContinue)) { throw 'Get-Fingerprint was not defined by the 10.1 block' }

$root = Join-Path ([IO.Path]::GetTempPath()) ('fingerprint-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
$latin1 = [Text.Encoding]::GetEncoding(28591)
function B([string]$s) { , $latin1.GetBytes($s) }

# name -> exact bytes
$fixtures = [ordered]@{
    'lf.txt'       = (B "alpha`nbeta`ngamma`n")
    'crlf.txt'     = (B "alpha`r`nbeta`r`ngamma`r`n")
    'mixed.txt'    = (B "alpha`r`nbeta`ngamma`r`n")
    'lonecr.txt'   = (B "alpha`rbeta`r`n")
    'noeol.txt'    = (B "alpha`r`nbeta")
    'trailcr.txt'  = (B "alpha`r`nbeta`r")
    'bom_crlf.txt' = [byte[]]([byte[]](0xEF, 0xBB, 0xBF) + $latin1.GetBytes("alpha`r`nbeta`r`n"))
    'binary.bin'   = [byte[]](0x00, 0x0D, 0x0A, 0xFF, 0x0D, 0x0A, 0x7F, 0x0D)
}
# name -> expected lf-mode hex, raw-mode hex (identical literals in the .sh test)
$expected = [ordered]@{
    'lf.txt'       = @('4fdbc441ea7b546100e086ac1e4fc5ae6749b7314311c99db05be450eca12996', '4fdbc441ea7b546100e086ac1e4fc5ae6749b7314311c99db05be450eca12996')
    'crlf.txt'     = @('4fdbc441ea7b546100e086ac1e4fc5ae6749b7314311c99db05be450eca12996', 'c8dba68945249de9b4faed72b89e041e3df77ffff885122599e6c2f7c65a68b2')
    'mixed.txt'    = @('4fdbc441ea7b546100e086ac1e4fc5ae6749b7314311c99db05be450eca12996', '10ed6683680f49e00196f995b0e87f9a48fe44e16119f338fdd63d4ac4aed2e3')
    'lonecr.txt'   = @('558bbba819eb2c82a290db0729b065f60c1934745f4b5ed0be0a05a4f8c4f281', '32a71235b900461a387ce14c151e761c06330bf8efc5370c70b5f117c1d901f9')
    'noeol.txt'    = @('bbfb79e82216bd2db1ad2c507d44ddf80aeb12f64f9562056afe93aad43154d9', '4854aaef74503959fd26363306e2ef967a9d50bdda90d033a3a4acacbbd57547')
    'trailcr.txt'  = @('aafd61de9a3a1d5bddc8f2c70795cce8e095a3acf056f3ac9cdd5e6121e86530', '9f582519fb21e19307c20b3c7734a71fc7631d4ae779b8c219e361eb8c40271c')
    'bom_crlf.txt' = @('bf7a11618542a830d64e5aeb970f1c6cc67cfce607ced9603efb2a696b9b2160', 'c3660080e3eee0ef1c03dd97ef4bb91bb952cf45f1ac2d52b2360e05fb201968')
    'binary.bin'   = @('d80d66c7ab3f740bc73e2642caa67712cfb0add253425da2bd2efec06b3feff5', 'eb5f875e5217953e083261e490e017d22abd45308947539cc52509c182530e3e')
}

$failures = 0; $total = 0
function Assert-Equal($name, $actual, $want) {
    $script:total++
    if ($actual -ceq $want) { Write-Output ("PASS  {0}" -f $name) }
    else { $script:failures++; Write-Output ("FAIL  {0}`n        got      {1}`n        expected {2}" -f $name, $actual, $want) }
}

try {
    Write-Output ("host: PowerShell {0} ({1}); Get-Fingerprint extracted from PROTOCOL.md section 10.1" -f $PSVersionTable.PSVersion, $PSVersionTable.PSEdition)
    foreach ($name in $fixtures.Keys) { [IO.File]::WriteAllBytes((Join-Path $root $name), [byte[]]$fixtures[$name]) }

    Write-Output '--- 8 fixtures x 2 modes, against digests shared with the Bash test ---'
    foreach ($name in $fixtures.Keys) {
        $p = Join-Path $root $name
        Assert-Equal "$name lf"  (Get-Fingerprint $p 'lf')  ("sha256-lf:"  + $expected[$name][0])
        Assert-Equal "$name raw" (Get-Fingerprint $p 'raw') ("sha256-raw:" + $expected[$name][1])
    }

    Write-Output '--- properties ---'
    Assert-Equal 'default mode is lf' (Get-Fingerprint (Join-Path $root 'crlf.txt')) ("sha256-lf:" + $expected['crlf.txt'][0])
    Assert-Equal 'LF, CRLF and mixed files share one lf fingerprint' ((@('lf.txt', 'crlf.txt', 'mixed.txt') | ForEach-Object { Get-Fingerprint (Join-Path $root $_) 'lf' } | Select-Object -Unique).Count) 1
    Assert-Equal 'LF and CRLF files have DIFFERENT raw fingerprints' ((Get-Fingerprint (Join-Path $root 'lf.txt') 'raw') -ceq (Get-Fingerprint (Join-Path $root 'crlf.txt') 'raw')) $false
    Assert-Equal 'a lone CR is NOT normalized away (lf mode still differs from the LF file)' ((Get-Fingerprint (Join-Path $root 'lonecr.txt') 'lf') -ceq (Get-Fingerprint (Join-Path $root 'lf.txt') 'lf')) $false
    Assert-Equal 'output is lowercase hex only' ((Get-Fingerprint (Join-Path $root 'bom_crlf.txt') 'lf') -cmatch '^sha256-(lf|raw):[0-9a-f]{64}$') $true
    Assert-Equal 'raw mode equals Get-FileHash lower-cased' ((Get-Fingerprint (Join-Path $root 'crlf.txt') 'raw').Substring(11)) ((Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root 'crlf.txt')).Hash.ToLowerInvariant())

    Write-Output '--- relative paths (the .NET-vs-PowerShell current-directory trap) ---'
    Push-Location -LiteralPath $root
    try { Assert-Equal 'relative path resolves against PowerShell location' (Get-Fingerprint 'crlf.txt' 'lf') ("sha256-lf:" + $expected['crlf.txt'][0]) } finally { Pop-Location }

    Write-Output '--- error path: a missing file must fail loudly, never yield a plausible hash ---'
    $threw = $false; try { $null = Get-Fingerprint (Join-Path $root 'does-not-exist.txt') 'lf' } catch { $threw = $true }
    Assert-Equal 'missing file throws' $threw $true

    Write-Output '--- git multi-device scenario (scratch repos) ---'
    if (Get-Command git -ErrorAction SilentlyContinue) {
        function Invoke-Git { $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'; try { & git @args 2>&1 | Out-Null } finally { $ErrorActionPreference = $prev } }
        $g = Join-Path $root 'git'; New-Item -ItemType Directory -Path $g | Out-Null
        $origin = Join-Path $g 'origin'
        Invoke-Git init -q $origin
        Invoke-Git -C $origin config core.autocrlf false
        Invoke-Git -C $origin config user.email 'test@example.invalid'
        Invoke-Git -C $origin config user.name 'test'
        [IO.File]::WriteAllBytes((Join-Path $origin 'dep.m'), $latin1.GetBytes("a = 1;`nb = 2;`n"))
        Invoke-Git -C $origin add dep.m
        Invoke-Git -C $origin commit -q -m 'x'
        Invoke-Git -c core.autocrlf=true  clone -q $origin (Join-Path $g 'winlike')
        Invoke-Git -c core.autocrlf=input clone -q $origin (Join-Path $g 'unixlike')
        $w = Join-Path (Join-Path $g 'winlike') 'dep.m'; $u = Join-Path (Join-Path $g 'unixlike') 'dep.m'; $o = Join-Path $origin 'dep.m'
        Assert-Equal 'the autocrlf=true checkout really has CRLF on disk' ((([IO.File]::ReadAllBytes($w)) -contains 13)) $true
        Assert-Equal 'raw fingerprints DIFFER between the two checkouts (the false-STALE problem)' ((Get-Fingerprint $w 'raw') -ceq (Get-Fingerprint $u 'raw')) $false
        Assert-Equal 'lf fingerprints are IDENTICAL across both checkouts and the origin' ((@($w, $u, $o) | ForEach-Object { Get-Fingerprint $_ 'lf' } | Select-Object -Unique).Count) 1
    } else { Write-Output 'SKIP  git not found; multi-device scenario not exercised' }
}
finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }

Write-Output ("{0} of {1} assertions passed" -f ($total - $failures), $total)
if ($failures -gt 0) { exit 1 } else { exit 0 }
