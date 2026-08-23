#!/usr/bin/env python3
"""
validate_trace.py — Source trace validator for federal_save_act ACL2 project.

Checks:
1. Every defaxiom in .lisp files has a row in sources/clause_trace.csv
2. Every source_id in clause_trace.csv exists in source_manifest.json
3. Every axiom_name in clause_trace.csv exists in the specified .lisp file
4. Every label is one of the allowed categories
5. No row references a missing ACL2 event

Exit code: 0 = all checks pass, 1 = any check fails
"""

import csv
import json
import re
import sys
import os
from pathlib import Path

# Who makes the determination an axiom encodes.  The logic (defun/defthm)
# has no grey areas; every grey area is a CHOICE, and this says whose.
ALLOWED_DECIDERS = {
    "legislature",        # statutory text: Congress chose these words
    "court",              # doctrine and statutory interpretation
    "fact-finder",        # empirical findings (trial court / record)
    "party-stipulation",  # conceded by both sides, or conceded arguendo
}

# Books that must contain NO defaxiom (neutrality lint).  Every legal
# choice lives in a party, hinge, facts, scenario, or generated text book.
NEUTRAL_BOOKS = {
    "lib/enum_list.lisp", "lib/lsm.lisp",
    "federal_save_act_core.lisp", "federal_save_act_process.lisp",
    "federal_save_act_document_rules.lisp", "federal_save_act_process_table.lisp",
    "federal_save_act_removal_table.lisp", "federal_save_act_removal_invariants.lisp",
    "federal_save_act_voting_id_rules.lisp", "federal_save_act_voting_table.lisp",
    "federal_save_act_voting_invariants.lisp", "federal_save_act_functional_instantiation.lisp",
    "federal_save_act_process_invariants.lisp", "federal_save_act_deep_process_invariants.lisp",
    "federal_save_act_document_proofs.lisp", "federal_save_act_consistency_check.lisp",
    "federal_save_act_burden_proofs.lisp", "federal_save_act_existentials.lisp",
    "federal_save_act_doctrine_proofs.lisp", "federal_save_act_model_consistency.lisp",
    "federal_save_act_independence.lisp", "federal_save_act_hinge_common.lisp",
}

ALLOWED_LABELS = {
    "TEXT_FACT",
    "DOCTRINAL_RULE",
    "EMPIRICAL_ASSUMPTION",
    "INTERPRETIVE_ASSUMPTION",
    "INTERPRETATION_CHALLENGER",
    "INTERPRETATION_GOVERNMENT",
    "PROCESS_RULE",
    "BRIDGE_RULE",
    "SCENARIO_FACT",
    "PROHIBITION",
    "EXCEPTION",
    "PROCEDURAL_FACT",
}

def find_defaxioms(lisp_dir):
    """Scan all .lisp files and return {axiom_name: filename}."""
    axioms = {}
    for f in sorted(list(Path(lisp_dir).glob("*.lisp")) + list(Path(lisp_dir).glob("lib/*.lisp"))):
        content = f.read_text(encoding="utf-8", errors="replace")
        rel = f.relative_to(lisp_dir).as_posix()
        for m in re.finditer(r'^\s*\(defaxiom\s+([\w\-]+)', content, re.MULTILINE):
            axioms[m.group(1)] = rel
    return axioms

def find_defthms(lisp_dir):
    """Scan all .lisp files and return {thm_name: filename}."""
    thms = {}
    for f in sorted(Path(lisp_dir).glob("*.lisp")):
        content = f.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(r'\(defthm\s+([\w\-]+)', content):
            thms[m.group(1)] = f.name
    return thms

def load_clause_trace(csv_path):
    """Load clause_trace.csv and return list of rows."""
    rows = []
    with open(csv_path, "r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)
    return rows

def load_source_manifest(json_path):
    """Load source_manifest.json and return set of source IDs."""
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    ids = set()
    if isinstance(data, list):
        for item in data:
            if "id" in item:
                ids.add(item["id"])
            if "source_id" in item:
                ids.add(item["source_id"])
    elif isinstance(data, dict):
        if "sources" in data:
            for item in data["sources"]:
                if "id" in item:
                    ids.add(item["id"])
                if "source_id" in item:
                    ids.add(item["source_id"])
    return ids

def main():
    project_root = Path(os.environ.get("PROJECT_ROOT", "."))
    csv_path = project_root / "sources" / "clause_trace.csv"
    json_path = project_root / "sources" / "source_manifest.json"

    errors = []
    warnings = []

    # --- Check 0: Files exist ---
    if not csv_path.exists():
        print(f"ERROR: {csv_path} not found")
        sys.exit(1)
    if not json_path.exists():
        print(f"ERROR: {json_path} not found")
        sys.exit(1)

    # --- Load data ---
    model_dir = project_root / "model"
    all_axioms = find_defaxioms(model_dir)
    all_thms = find_defthms(model_dir)
    all_events = {**all_axioms, **all_thms}
    trace_rows = load_clause_trace(csv_path)
    source_ids = load_source_manifest(json_path)

    traced_axioms = set()

    print(f"Found {len(all_axioms)} defaxioms across .lisp files")
    print(f"Found {len(all_thms)} defthms across .lisp files")
    print(f"Found {len(trace_rows)} rows in clause_trace.csv")
    print(f"Found {len(source_ids)} source IDs in source_manifest.json")
    print()

    # --- Check 1: Every defaxiom has a row in clause_trace.csv ---
    for row in trace_rows:
        name = row.get("axiom_name", row.get("event_name", "")).strip()
        if name:
            traced_axioms.add(name)

    untraced = set(all_axioms.keys()) - traced_axioms
    for ax in sorted(untraced):
        errors.append(f"CHECK 1 FAIL: defaxiom '{ax}' in {all_axioms[ax]} has no row in clause_trace.csv")

    # --- Check 2: Every source_id in clause_trace.csv exists in source_manifest.json ---
    for i, row in enumerate(trace_rows, 1):
        sid = row.get("source_id", "").strip()
        if sid and sid != "n/a" and sid not in source_ids:
            errors.append(f"CHECK 2 FAIL: Row {i} references source_id '{sid}' not found in source_manifest.json")

    # --- Check 3: Every axiom_name in clause_trace.csv exists in a .lisp file ---
    for i, row in enumerate(trace_rows, 1):
        name = row.get("axiom_name", row.get("event_name", "")).strip()
        if name and name not in all_events:
            errors.append(f"CHECK 3 FAIL: Row {i} references event '{name}' not found in any .lisp file")

    # --- Check 4: Every label is one of the allowed categories ---
    for i, row in enumerate(trace_rows, 1):
        label = row.get("label", row.get("category", "")).strip()
        if label and label not in ALLOWED_LABELS:
            errors.append(f"CHECK 4 FAIL: Row {i} has label '{label}' not in allowed set: {ALLOWED_LABELS}")

    # --- Check 5: Every traced defaxiom carries a valid decider tag ---
    for i, row in enumerate(trace_rows, 1):
        name = row.get("axiom_name", "").strip()
        if name in all_axioms:
            dec = row.get("decider", "").strip()
            if dec not in ALLOWED_DECIDERS:
                errors.append(f"CHECK 5 FAIL: Row {i} ('{name}') decider '{dec}' not in {sorted(ALLOWED_DECIDERS)}")

    # --- Check 6: Neutrality lint — no defaxiom in a neutral book ---
    for ax, book in all_axioms.items():
        if book in NEUTRAL_BOOKS:
            errors.append(f"CHECK 6 FAIL: defaxiom '{ax}' appears in NEUTRAL book {book}; legal choices belong in party/hinge/facts/scenario/text_rules books")
    neutral_present = [b for b in NEUTRAL_BOOKS if (model_dir / b).exists()]
    print(f"Neutrality lint: {len(neutral_present)} neutral books checked, {sum(1 for b in all_axioms.values() if b in NEUTRAL_BOOKS)} violations")
    deciders = {}
    for row in trace_rows:
        if row.get("axiom_name", "").strip() in all_axioms:
            deciders[row.get("decider", "")] = deciders.get(row.get("decider", ""), 0) + 1
    print(f"Deciders: {deciders}")
    print()

    # --- Print results ---
    if warnings:
        print("WARNINGS:")
        for w in warnings:
            print(f"  {w}")
        print()

    if errors:
        print("ERRORS:")
        for e in errors:
            print(f"  {e}")
        print()
        print(f"RESULT: {len(errors)} errors, {len(warnings)} warnings — FAIL")
        sys.exit(1)
    else:
        print(f"RESULT: 0 errors, {len(warnings)} warnings — PASS")
        sys.exit(0)

if __name__ == "__main__":
    main()
