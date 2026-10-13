# Runs every test in this directory: all test_*.ps1 under the CURRENT PowerShell host
# (Windows PowerShell 5.1 or pwsh 7), then all test_*.sh if a bash is available.
# Exit codes: 0 = everything ran and passed; 1 = a test failed; 2 = nothing failed but
# the Bash tests could NOT run (no bash found) -- so the run is INCOMPLETE, not green.
# Pass -SkipBash to acknowledge that on purpose (then a pass exits 0).
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tests\run_all.ps1
#   pwsh -NoProfile -File tests/run_all.ps1
param([switch]$SkipBash)

$failed  = 0
$incomplete = $false
$hostExe = (Get-Process -Id $PID).Path

foreach ($t in (Get-ChildItem -LiteralPath $PSScriptRoot -Filter 'test_*.ps1' | Sort-Object Name)) {
    Write-Output ('=== ' + $t.Name + ' ===')
    & $hostExe -NoProfile -ExecutionPolicy Bypass -File $t.FullName
    if ($LASTEXITCODE -ne 0) { $failed++; Write-Output ('FAILED: ' + $t.Name) }
}

$bashExe = $null
$cmd = Get-Command bash -ErrorAction SilentlyContinue
if ($cmd) { $bashExe = $cmd.Source }
elseif (Test-Path -LiteralPath "$env:ProgramFiles\Git\bin\bash.exe") { $bashExe = "$env:ProgramFiles\Git\bin\bash.exe" }

if ($SkipBash) {
    Write-Output 'NOTE: -SkipBash given; the Bash tests were deliberately NOT run.'
} elseif ($bashExe) {
    foreach ($t in (Get-ChildItem -LiteralPath $PSScriptRoot -Filter 'test_*.sh' | Sort-Object Name)) {
        Write-Output ('=== ' + $t.Name + ' (bash) ===')
        & $bashExe $t.FullName
        if ($LASTEXITCODE -ne 0) { $failed++; Write-Output ('FAILED: ' + $t.Name) }
    }
} else {
    $incomplete = $true
    Write-Output 'INCOMPLETE: bash was not found, so the Bash tests did NOT run. This is not a green run (pass -SkipBash to acknowledge it).'
}

Write-Output ('{0} test file(s) failed' -f $failed)
if ($failed -gt 0) { exit 1 } elseif ($incomplete) { exit 2 } else { exit 0 }
