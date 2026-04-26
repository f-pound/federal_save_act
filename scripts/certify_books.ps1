# certify_books.ps1 — Run ACL2 certify-book on all Federal SAVE Act books.
#
# Produces .cert files in strict dependency order.
# Books with defaxiom (or inheriting it) use :defaxioms-okp t.
#
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\certify_books.ps1
# Logs are saved to logs\certify\

# --- Strict dependency order ---
# Each entry: @("book_name", "clean|defaxiom")

$books = @(
  # Layer 0: base clean
  @("model/federal_save_act_core", "clean"),
  @("model/federal_save_act_process", "clean"),

  # Layer 1: source-traced axiom book
  @("model/federal_save_act_facts", "defaxiom"),

  # Layer 2: hinge dependency (includes facts)
  @("model/federal_save_act_hinge_common", "defaxiom"),

  # Layer 3: hinge interpretation (includes hinge_common)
  @("model/federal_save_act_hinge_mandatory", "defaxiom"),
  @("model/federal_save_act_hinge_discretionary", "defaxiom"),

  # Layer 4: downstream (includes facts)
  @("model/federal_save_act_existentials", "defaxiom"),
  @("model/federal_save_act_burden_proofs", "defaxiom"),
  @("model/federal_save_act_doctrine_proofs", "defaxiom"),
  @("model/federal_save_act_model_consistency", "defaxiom"),
  @("model/federal_save_act_independence", "defaxiom"),
  @("model/federal_save_act_challenger_model", "defaxiom"),
  @("model/federal_save_act_government_model", "defaxiom"),

  # Layer 5: clean process chain (no defaxiom dependency)
  @("model/federal_save_act_process_invariants", "clean"),
  @("model/federal_save_act_deep_process_invariants", "clean"),
  @("model/federal_save_act_document_proofs", "clean"),

  # Layer 6: consistency check (includes core only)
  @("model/federal_save_act_consistency_check", "clean")
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

foreach ($entry in $books) {
  Certify-Book -Book $entry[0] -Mode $entry[1]
}

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
