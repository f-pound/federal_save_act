#!/usr/bin/env bash
# certify_books.sh — Run ACL2 certify-book on all Federal SAVE Act books.
#
# Produces .cert files in strict dependency order.
# Books with defaxiom (or inheriting it) use :defaxioms-okp t.
#
# Usage: ./scripts/certify_books.sh
# Logs are saved to logs/certify/
set -euo pipefail

LOG_DIR="logs/certify"
mkdir -p "$LOG_DIR"

TOTAL_CERT=0
TOTAL_FAIL=0
FAILED_BOOKS=()

# Determine ACL2 runner
if command -v docker &>/dev/null && docker compose version &>/dev/null; then
  run_certify_clean() {
    echo "(certify-book \"$1\" ?)" | \
      docker compose run --rm acl2 acl2 2>/dev/null
  }
  run_certify_defaxiom() {
    echo "(certify-book \"$1\" ? nil :defaxioms-okp t)" | \
      docker compose run --rm acl2 acl2 2>/dev/null
  }
elif command -v acl2 &>/dev/null; then
  run_certify_clean() {
    echo "(certify-book \"$1\" ?)" | acl2 2>&1
  }
  run_certify_defaxiom() {
    echo "(certify-book \"$1\" ? nil :defaxioms-okp t)" | acl2 2>&1
  }
else
  echo "ERROR: Neither docker nor acl2 found on PATH."
  exit 1
fi

certify_book() {
  local book="$1"
  local mode="$2"  # "clean" or "defaxiom"
  local logfile="$LOG_DIR/${book}.log"

  if [ "$mode" = "clean" ]; then
    output=$(run_certify_clean "$book")
  else
    output=$(run_certify_defaxiom "$book")
  fi
  echo "$output" > "$logfile"

  if [ -f "${book}.cert" ]; then
    local label=""
    [ "$mode" = "defaxiom" ] && label="  (defaxioms-okp)"
    echo "  CERT  $book$label  -> $logfile"
    TOTAL_CERT=$((TOTAL_CERT + 1))
  else
    echo "  FAIL  $book  -> $logfile"
    FAILED_BOOKS+=("$book")
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
  fi
}

echo "=== ACL2 certify-book: Federal SAVE Act ==="
echo "Logs: $LOG_DIR/"
echo ""

# Layer 0: base clean
certify_book model/federal_save_act_core clean
certify_book model/federal_save_act_process clean

# Layer 1: source-traced axiom book
certify_book model/federal_save_act_facts defaxiom

# Layer 2: hinge dependency (includes facts)
certify_book model/federal_save_act_hinge_common defaxiom

# Layer 3: hinge interpretation (includes hinge_common)
certify_book model/federal_save_act_hinge_mandatory defaxiom
certify_book model/federal_save_act_hinge_discretionary defaxiom

# Layer 4: downstream (includes facts)
certify_book model/federal_save_act_existentials defaxiom
certify_book model/federal_save_act_burden_proofs defaxiom
certify_book model/federal_save_act_doctrine_proofs defaxiom
certify_book model/federal_save_act_model_consistency defaxiom
certify_book model/federal_save_act_independence defaxiom
certify_book model/federal_save_act_challenger_model defaxiom
certify_book model/federal_save_act_government_model defaxiom

# Layer 5: clean process chain (no defaxiom dependency)
certify_book model/federal_save_act_process_invariants clean
certify_book model/federal_save_act_deep_process_invariants clean
certify_book model/federal_save_act_document_proofs clean

# Layer 6: consistency check (includes core only)
certify_book model/federal_save_act_consistency_check clean

echo ""
echo "=== Summary ==="
echo "Certified: $TOTAL_CERT"
echo "Failed:    $TOTAL_FAIL"

if [ "$TOTAL_FAIL" -gt 0 ]; then
  echo ""
  echo "FAILED BOOKS:"
  for b in "${FAILED_BOOKS[@]}"; do
    echo "  - $b"
  done
  exit 1
else
  echo "All 17 books certified."
  exit 0
fi
