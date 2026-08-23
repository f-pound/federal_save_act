#!/usr/bin/env bash
# certify_books.sh — Run ACL2 certify-book on all Federal SAVE Act books.
#
# Produces .cert files in strict dependency order.
# Books with defaxiom (or inheriting it) use :defaxioms-okp t.
#
# Usage: ./scripts/certify_books.sh
# Runner selection (first match wins):
#   $ACL2_CMD            — explicit command that reads ACL2 forms on stdin
#   docker compose       — uses docker-compose.yml (atwalter/acl2)
#   acl2 on PATH         — native install (e.g. `brew install acl2`)
# Logs are saved to logs/certify/
set -euo pipefail

cd "$(dirname "$0")/.."
LOG_DIR="logs/certify"
mkdir -p "$LOG_DIR"

TOTAL_CERT=0
TOTAL_FAIL=0
FAILED_BOOKS=()

if [ -n "${ACL2_CMD:-}" ]; then
  run_acl2() { $ACL2_CMD 2>&1; }
elif command -v acl2 &>/dev/null; then
  run_acl2() { acl2 2>&1; }
elif command -v docker &>/dev/null && docker compose version &>/dev/null; then
  run_acl2() { docker compose run --rm -T acl2 acl2 2>/dev/null; }
else
  echo "ERROR: set ACL2_CMD, or install acl2, or install docker."
  exit 1
fi

certify_book() {
  local book="$1"
  local mode="$2"  # "clean" or "defaxiom"
  local logfile="$LOG_DIR/$(basename "$book").log"
  rm -f "${book}.cert"
  if [ "$mode" = "clean" ]; then
    echo "(certify-book \"$book\" ?)" | run_acl2 > "$logfile" || true
  else
    echo "(certify-book \"$book\" ? nil :defaxioms-okp t)" | run_acl2 > "$logfile" || true
  fi
  local qed
  qed=$(grep -c '^Q\.E\.D\.' "$logfile" || true)
  if [ -f "${book}.cert" ]; then
    local label=""
    [ "$mode" = "defaxiom" ] && label="  (defaxioms-okp)"
    echo "  CERT  $book  ($qed Q.E.D.)$label"
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

# Modeled clauses must be present verbatim in both tracked bill texts.
python3 tools/check_text_stability.py

# Consistency-audit book and trusted-base report must match their generators.
python3 tools/gen_consistency_audit.py --check
python3 tools/print_axioms.py --check

# Generated book must match its IR before anything is certified.
python3 tools/clauses_to_acl2.py data/parsed/federal_save_act_document_rules.json data/parsed/federal_save_act_process_table.json data/parsed/federal_save_act_removal_table.json data/parsed/federal_save_act_text_rules.json data/parsed/federal_save_act_voting_id_rules.json data/parsed/federal_save_act_voting_table.json data/parsed/federal_save_act_voting_text_rules.json --check --english --ace

# Layer L: generic lemma libraries (no statute content, no defaxiom)
certify_book model/lib/enum_list clean
certify_book model/lib/lsm clean

# Layer 0: base clean books
certify_book model/federal_save_act_core clean
certify_book model/federal_save_act_document_rules clean
certify_book model/federal_save_act_process_table clean
certify_book model/federal_save_act_removal_table clean
certify_book model/federal_save_act_process clean
certify_book model/federal_save_act_removal_invariants clean
certify_book model/federal_save_act_voting_id_rules clean
certify_book model/federal_save_act_voting_table clean
certify_book model/federal_save_act_voting_invariants clean
certify_book model/federal_save_act_functional_instantiation clean

# Layer 1g: generated text-derived axioms
certify_book model/federal_save_act_text_rules defaxiom
certify_book model/federal_save_act_voting_text_rules defaxiom

# Layer 1: source-traced axiom book + shared scenario
certify_book model/federal_save_act_facts defaxiom
certify_book model/federal_save_act_scenario defaxiom

# Layer 2/3: hinge books
certify_book model/federal_save_act_hinge_common defaxiom
certify_book model/federal_save_act_hinge_mandatory defaxiom
certify_book model/federal_save_act_hinge_discretionary defaxiom

# Layer 4: downstream (includes facts / scenario)
certify_book model/federal_save_act_existentials defaxiom
certify_book model/federal_save_act_burden_proofs defaxiom
certify_book model/federal_save_act_doctrine_proofs defaxiom
certify_book model/federal_save_act_model_consistency defaxiom
certify_book model/federal_save_act_independence defaxiom
certify_book model/federal_save_act_challenger_model defaxiom
certify_book model/federal_save_act_government_model defaxiom

# Layer 5: clean process chain (library instances, no defaxiom)
certify_book model/federal_save_act_process_invariants clean
certify_book model/federal_save_act_deep_process_invariants clean
certify_book model/federal_save_act_document_proofs clean

# Layer 6: consistency check (includes core only) and the party-theory consistency audit
certify_book model/federal_save_act_consistency_check clean
certify_book model/federal_save_act_consistency_audit clean

echo ""
echo "=== Summary ==="
echo "Certified: $TOTAL_CERT"
echo "Failed:    $TOTAL_FAIL"
if [ "$TOTAL_FAIL" -gt 0 ]; then
  echo ""; echo "FAILED BOOKS:"; for b in "${FAILED_BOOKS[@]}"; do echo "  - $b"; done
  exit 1
fi
echo "All $TOTAL_CERT books certified."
