# certify_all.ps1 — Run the full Federal SAVE Act ACL2 proof suite.
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\certify_all.ps1
# Requires: docker compose

$books = @(
  "federal_save_act_consistency_check",
  "federal_save_act_process_invariants",
  "federal_save_act_deep_process_invariants",
  "federal_save_act_hinge_common",
  "federal_save_act_hinge_mandatory",
  "federal_save_act_hinge_discretionary",
  "federal_save_act_existentials",
  "federal_save_act_independence",
  "federal_save_act_document_proofs",
  "federal_save_act_burden_proofs",
  "federal_save_act_doctrine_proofs",
  "federal_save_act_model_consistency",
  "federal_save_act_challenger_model",
  "federal_save_act_government_model"
)

$totalQ = 0; $totalF = 0; $failedBooks = @()

Write-Host "=== Federal SAVE Act ACL2 Proof Suite ==="
Write-Host ""

# Step 1: Trace validation
Write-Host "--- Trace Validation ---"
$env:PROJECT_ROOT = "."
python tools/validate_trace.py
Write-Host ""

# Step 2: ACL2 books
Write-Host "--- ACL2 Books ---"
foreach ($b in $books) {
  $out = cmd /c "docker compose run --rm acl2 acl2 < ${b}.lisp 2>NUL" 2>$null
  $qed = ($out | Select-String "Q\.E\.D\.").Count
  $fail = ($out | Select-String "FAILED").Count
  $totalQ += $qed; $totalF += $fail
  if ($fail -gt 0) {
    Write-Host "  FAIL  $b  ($qed QED, $fail FAIL)"
    $failedBooks += $b
  } else {
    Write-Host "  OK    $b  ($qed QED)"
  }
}

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "Total Q.E.D.: $totalQ"
Write-Host "Total FAILED: $totalF"

if ($totalF -gt 0) {
  Write-Host ""
  Write-Host "FAILED BOOKS:"
  foreach ($fb in $failedBooks) { Write-Host "  - $fb" }
  exit 1
} else {
  Write-Host "All books passed."
  exit 0
}
