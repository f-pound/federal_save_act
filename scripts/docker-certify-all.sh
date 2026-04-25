#!/bin/bash
# certify-all.sh — Run all ACL2 proofs via Docker
# Usage: ./scripts/docker-certify-all.sh
# Requires: docker compose (with docker-compose.yml in project root)
set -euo pipefail

cd "$(dirname "$0")/.."

PASS=0
FAIL=0

run_book() {
  local name="$1"
  local file="$2"
  echo ""
  echo "=== $name ==="
  if docker compose run --rm acl2 acl2 < "$file" > "reports/${file%.lisp}.log" 2>&1; then
    echo "  Exit code: 0"
  fi
  local qed=$(grep -c "Q\.E\.D\." "reports/${file%.lisp}.log" || true)
  local failed=$(grep -c "FAILED" "reports/${file%.lisp}.log" || true)
  echo "  Q.E.D.: $qed"
  echo "  FAILED: $failed"
  if [ "$failed" -gt 0 ]; then
    FAIL=$((FAIL + 1))
    echo "  STATUS: ❌ FAIL"
  else
    PASS=$((PASS + 1))
    echo "  STATUS: ✅ PASS"
  fi
}

echo "Federal SAVE Act ACL2 Proof Certification"
echo "=========================================="
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Certify dependency books first
echo ""
echo "--- Certifying dependency books ---"
echo '(certify-book "federal_save_act_core" ?)' | docker compose run --rm acl2 acl2 > reports/certify_core.log 2>&1 || true
echo '(certify-book "federal_save_act_facts" ?)' | docker compose run --rm acl2 acl2 > reports/certify_facts.log 2>&1 || true

# Run all proof books
run_book "Consistency Check" "federal_save_act_consistency_check.lisp"
run_book "Process Model" "federal_save_act_process.lisp"
run_book "Hinge Theorems" "federal_save_act_hinge.lisp"
run_book "Challenger Model" "federal_save_act_challenger_model.lisp"
run_book "Government Model" "federal_save_act_government_model.lisp"

echo ""
echo "=========================================="
echo "RESULTS: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  echo "STATUS: ❌ SOME BOOKS FAILED"
  exit 1
else
  echo "STATUS: ✅ ALL BOOKS PASSED"
  exit 0
fi
