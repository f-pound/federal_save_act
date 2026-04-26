#!/usr/bin/env bash
# certify_all.sh — Run the full Federal SAVE Act ACL2 proof suite.
# Usage: ./scripts/certify_all.sh
# Requires: docker compose OR native acl2 on PATH
set -euo pipefail

BOOKS=(
  federal_save_act_consistency_check.lisp
  federal_save_act_process_invariants.lisp
  federal_save_act_deep_process_invariants.lisp
  federal_save_act_hinge_common.lisp
  federal_save_act_hinge_mandatory.lisp
  federal_save_act_hinge_discretionary.lisp
  federal_save_act_existentials.lisp
  federal_save_act_independence.lisp
  federal_save_act_document_proofs.lisp
  federal_save_act_burden_proofs.lisp
  federal_save_act_doctrine_proofs.lisp
  federal_save_act_model_consistency.lisp
  federal_save_act_challenger_model.lisp
  federal_save_act_government_model.lisp
)

TOTAL_QED=0
TOTAL_FAIL=0
FAILED_BOOKS=()

# Determine ACL2 runner
if command -v docker &>/dev/null && docker compose version &>/dev/null; then
  run_acl2() { docker compose run --rm acl2 acl2 < "$1" 2>&1; }
elif command -v acl2 &>/dev/null; then
  run_acl2() { acl2 < "$1" 2>&1; }
else
  echo "ERROR: Neither docker nor acl2 found on PATH."
  echo "Install Docker Desktop or ACL2 to run the proof suite."
  exit 1
fi

echo "=== Federal SAVE Act ACL2 Proof Suite ==="
echo ""

# Step 1: Trace validation
echo "--- Trace Validation ---"
if command -v python3 &>/dev/null; then
  PROJECT_ROOT=. python3 tools/validate_trace.py
elif command -v python &>/dev/null; then
  PROJECT_ROOT=. python tools/validate_trace.py
else
  echo "WARNING: Python not found, skipping trace validation."
fi
echo ""

# Step 2: ACL2 books
echo "--- ACL2 Books ---"
for book in "${BOOKS[@]}"; do
  name="${book%.lisp}"
  output=$(run_acl2 "$book")
  qed=$(echo "$output" | grep -c "Q\.E\.D\." || true)
  failed=$(echo "$output" | grep -c "FAILED" || true)
  TOTAL_QED=$((TOTAL_QED + qed))
  TOTAL_FAIL=$((TOTAL_FAIL + failed))
  if [ "$failed" -gt 0 ]; then
    echo "  FAIL  $name  ($qed QED, $failed FAIL)"
    FAILED_BOOKS+=("$name")
  else
    echo "  OK    $name  ($qed QED)"
  fi
done

echo ""
echo "=== Summary ==="
echo "Total Q.E.D.: $TOTAL_QED"
echo "Total FAILED: $TOTAL_FAIL"

if [ "$TOTAL_FAIL" -gt 0 ]; then
  echo ""
  echo "FAILED BOOKS:"
  for b in "${FAILED_BOOKS[@]}"; do
    echo "  - $b"
  done
  exit 1
else
  echo "All books passed."
  exit 0
fi
