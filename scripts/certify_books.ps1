# certify_books.ps1 — Run ACL2 certify-book on all Federal SAVE Act books.
#
# This produces .cert files for each book, which is the standard ACL2
# certification artifact. Books are certified in dependency order.
#
# Books containing defaxiom (or including books that do) are certified
# with :defaxioms-okp t. Books with no defaxiom chain are certified
# without that flag (clean certification).
#
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\certify_books.ps1
# Logs are saved to logs\certify\

# --- Book classification ---
$cleanBooks = @(
  "federal_save_act_core",
  "federal_save_act_process",
  "federal_save_act_consistency_check"
)

$cleanDownstream = @(
  "federal_save_act_process_invariants",
  "federal_save_act_deep_process_invariants",
  "federal_save_act_document_proofs"
)

$defaxiomBooks = @(
  "federal_save_act_facts",
  "federal_save_act_hinge_mandatory",
  "federal_save_act_hinge_discretionary",
  "federal_save_act_challenger_model",
  "federal_save_act_government_model"
)

$inheritedBooks = @(
  "federal_save_act_hinge_common",
  "federal_save_act_existentials",
  "federal_save_act_burden_proofs",
  "federal_save_act_doctrine_proofs",
  "federal_save_act_model_consistency",
  "federal_save_act_independence"
)

$logDir = "logs\certify"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

$totalCert = 0; $totalFail = 0; $failedBooks = @()

function Certify-Book {
  param([string]$Book, [string]$Mode)
  $logFile = "$logDir\${Book}.log"

  if ($Mode -eq "clean") {
    $cmd = "(certify-book `"$Book`" ?)"
  } else {
    $cmd = "(certify-book `"$Book`" ? nil :defaxioms-okp t)"
  }

  $out = echo $cmd | docker compose run --rm acl2 acl2 2>$null
  $out | Out-File -FilePath $logFile -Encoding utf8

  if (Test-Path "${Book}.cert") {
    $label = if ($Mode -eq "defaxiom") { "  (defaxioms-okp)" } else { "" }
    Write-Host "  CERT  $Book$label  -> $logFile"
    $script:totalCert++
  } else {
    Write-Host "  FAIL  $Book  -> $logFile"
    $script:failedBooks += $Book
    $script:totalFail++
  }
}

Write-Host "=== ACL2 certify-book: Federal SAVE Act ==="
Write-Host "Logs: $logDir\"
Write-Host ""

Write-Host "--- Layer 0: Clean books (no defaxiom) ---"
foreach ($b in $cleanBooks) { Certify-Book -Book $b -Mode "clean" }

Write-Host "--- Layer 1: Defaxiom books ---"
foreach ($b in $defaxiomBooks) { Certify-Book -Book $b -Mode "defaxiom" }

Write-Host "--- Layer 2: Inherited defaxiom (includes facts) ---"
foreach ($b in $inheritedBooks) { Certify-Book -Book $b -Mode "defaxiom" }

Write-Host "--- Layer 2-3: Clean downstream (process chain) ---"
foreach ($b in $cleanDownstream) { Certify-Book -Book $b -Mode "clean" }

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "Certified: $totalCert"
Write-Host "Failed:    $totalFail"

if ($totalFail -gt 0) {
  Write-Host ""
  Write-Host "FAILED BOOKS:"
  foreach ($fb in $failedBooks) { Write-Host "  - $fb" }
  exit 1
} else {
  Write-Host "All 17 books certified."
  exit 0
}
