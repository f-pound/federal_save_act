# certify-all.ps1 — Run all ACL2 proofs via Docker (PowerShell)
# Usage: .\scripts\certify-all.ps1
# Requires: docker compose (with docker-compose.yml in project root)

$ErrorActionPreference = "Continue"
Push-Location (Split-Path $PSScriptRoot -Parent)

$pass = 0
$fail = 0

function Run-Book {
  param([string]$Name, [string]$File)
  Write-Host ""
  Write-Host "=== $Name ==="
  $logFile = "reports/$($File -replace '\.lisp$','').log"
  cmd /c "docker compose run --rm acl2 acl2 < $File" 2>&1 | Out-File -FilePath $logFile -Encoding ASCII
  $content = Get-Content $logFile -Raw
  $qed = ([regex]::Matches($content, "Q\.E\.D\.")).Count
  $failed = ([regex]::Matches($content, "FAILED")).Count
  Write-Host "  Q.E.D.: $qed"
  Write-Host "  FAILED: $failed"
  if ($failed -gt 0) {
    $script:fail++
    Write-Host "  STATUS: FAIL" -ForegroundColor Red
  } else {
    $script:pass++
    Write-Host "  STATUS: PASS" -ForegroundColor Green
  }
}

Write-Host "Federal SAVE Act ACL2 Proof Certification"
Write-Host "=========================================="
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')"

# Certify dependency books first
Write-Host ""
Write-Host "--- Certifying dependency books ---"
cmd /c "echo (certify-book ""federal_save_act_core"" ?) | docker compose run --rm acl2 acl2" 2>&1 | Out-File -FilePath "reports/certify_core.log" -Encoding ASCII
cmd /c "echo (certify-book ""federal_save_act_facts"" ?) | docker compose run --rm acl2 acl2" 2>&1 | Out-File -FilePath "reports/certify_facts.log" -Encoding ASCII

# Run all proof books
Run-Book "Consistency Check" "federal_save_act_consistency_check.lisp"
Run-Book "Process Model" "federal_save_act_process.lisp"
Run-Book "Hinge Theorems" "federal_save_act_hinge.lisp"
Run-Book "Challenger Model" "federal_save_act_challenger_model.lisp"
Run-Book "Government Model" "federal_save_act_government_model.lisp"

Write-Host ""
Write-Host "=========================================="
Write-Host "RESULTS: $pass passed, $fail failed"
if ($fail -gt 0) {
  Write-Host "STATUS: SOME BOOKS FAILED" -ForegroundColor Red
  Pop-Location
  exit 1
} else {
  Write-Host "STATUS: ALL BOOKS PASSED" -ForegroundColor Green
  Pop-Location
  exit 0
}
