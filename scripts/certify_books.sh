#!/usr/bin/env bash
# certify_books.sh — Run ACL2 certify-book on all Federal SAVE Act books.
#
# This produces .cert files for each book, which is the standard ACL2
# certification artifact. Books are certified in dependency order.
#
# Books containing defaxiom (or including books that do) are certified
# with :defaxioms-okp t. Books with no defaxiom chain are certified
# without that flag (clean certification).
#
# Usage: ./scripts/certify_books.sh
# Logs are saved to logs/certify/
set -euo pipefail

# --- Book classification ---
# Clean: no defaxiom in the book or its dependency chain
CLEAN_BOOKS=(
  federal_save_act_core
  federal_save_act_process
  federal_save_act_consistency_check
)

# Process chain (clean): depends on core/process, no defaxiom
CLEAN_DOWNSTREAM=(
  federal_save_act_process_invariants
  federal_save_act_deep_process_invariants
  federal_save_act_document_proofs
)

# Defaxiom books: contain defaxiom directly
DEFAXIOM_BOOKS=(
  federal_save_act_facts
  federal_save_act_hinge_mandatory
  federal_save_act_hinge_discretionary
  federal_save_act_challenger_model
  federal_save_act_government_model
)

# Inherited defaxiom: no defaxiom themselves, but include facts.lisp
INHERITED_BOOKS=(
  federal_save_act_hinge_common
  federal_save_act_existentials
  federal_save_act_burden_proofs
  federal_save_act_doctrine_proofs
  federal_save_act_model_consistency
  federal_save_act_independence
)

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

echo "--- Layer 0: Clean books (no defaxiom) ---"
for b in "${CLEAN_BOOKS[@]}"; do
  certify_book "$b" clean
done

echo "--- Layer 1: Defaxiom books ---"
for b in "${DEFAXIOM_BOOKS[@]}"; do
  certify_book "$b" defaxiom
done

echo "--- Layer 2: Inherited defaxiom (includes facts) ---"
for b in "${INHERITED_BOOKS[@]}"; do
  certify_book "$b" defaxiom
done

echo "--- Layer 2-3: Clean downstream (process chain) ---"
for b in "${CLEAN_DOWNSTREAM[@]}"; do
  certify_book "$b" clean
done

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
