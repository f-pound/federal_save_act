#!/usr/bin/env python3
"""
build_explorer_data.py — Build web/data/explorer.json from repository artifacts.

Merges:
  - data/parsed/explorer_graph.json  (curated dependency map)
  - data/parsed/federal_save_act_ace.json  (ACE controlled-English statements)
  - sources/source_manifest.json  (authoritative source metadata)
  - sources/clause_trace.csv  (axiom→source traceability)
  - version.json  (project metadata)

Output: web/data/explorer.json
"""

import csv
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REPO_URL = "https://github.com/f-pound/federal_save_act"

# ---- Curated plain-English explanations for each node ----
WHY_IT_MATTERS = {
    # Sources & Traceability
    "src-hr22": "This is the bill being analyzed. Every formal conclusion traces back to its actual text.",
    "src-nvra": "The NVRA is the existing federal baseline for voter registration. The SAVE Act modifies this framework.",
    "src-const-art1": "Article I §2 establishes who may vote in federal elections. Any registration requirement must respect this.",
    "src-const-17th": "The 17th Amendment extended direct election to senators. It reinforces the constitutional right to vote.",
    "src-const-5th": "The 5th Amendment's due process clause is the constitutional hook for challenging unreasonable voting burdens.",
    "src-crawford": "Crawford v. Marion County is the Supreme Court's controlling framework for evaluating voter ID laws.",
    "src-anderson": "Anderson v. Celebrezze established the balancing test: courts weigh the burden on voters against the state's interest.",
    "src-fish": "Fish v. Kobach found that strict proof-of-citizenship requirements blocked legitimate voters.",
    "src-burdick": "Burdick v. Takushi confirmed that reasonable, nondiscriminatory restrictions on voting are generally valid.",
    "src-trace-matrix": "The traceability matrix maps every formal axiom back to its authoritative legal source.",
    "src-clause-trace": "The clause trace links each ACL2 assumption to the specific statutory or case-law language it encodes.",
    "src-ace-statements": "Controlled-English translations make the formal predicates readable by legal professionals.",
    # Formalization & Assumptions
    "ax-citizen-a-qualified": "This ground fact sets up the test scenario: a real citizen, eligible to vote, who wants to register.",
    "ax-citizen-a-lacks-docs": "The critical scenario fact: the citizen does not have any qualifying documents, which triggers the SAVE Act's proof requirement.",
    "ax-protected-right": "Establishes that voting is constitutionally protected — the foundation for any burden analysis.",
    "ax-law-is-law": "Grounds the formal analysis in real legislation. Without this, the model would be about a hypothetical law.",
    "ax-registration-transaction": "Classifies the act of registering as a formal transaction subject to the SAVE Act's requirements.",
    "ax-statute-denies": "This is the crux: under the SAVE Act, lacking documents triggers a denial of registration.",
    "ax-no-fault": "HIGH RISK — This empirical claim (the citizen lacks documents through no fault of their own) is the most contestable assumption in the challenger's case. ~18,000 applicants were blocked in Kansas under a similar requirement.",
    "ax-material-burden": "HIGH RISK — The claim that obtaining qualifying documents is materially burdensome. Based on Crawford plurality language, not a holding.",
    "ax-burden-not-severe": "HIGH RISK — The government's counter-claim that the documentation burden is not severe. Directly contradicts the challenger's burden claim.",
    "ax-adequate-alt": "The government's argument that the SAVE Act's alternative process provides an adequate safety valve.",
    "ax-mandatory-reading": "Government's interpretation: 'shall make a determination' means mandatory approval when evidence meets standards.",
    "ax-discretionary-reading": "Challenger's interpretation: 'shall make a determination' means the official may still deny registration.",
    "ax-election-integrity": "A doctrinal assumption from Crawford: protecting election integrity is an important government interest.",
    "ax-reasonable-evenhanded": "A doctrinal claim: the SAVE Act's requirement is reasonable and applies evenhandedly to all applicants.",
    "ax-severe-defeats": "Anderson-Burdick doctrine: if a voting regulation imposes a severe burden, it is constitutionally invalid.",
    # Executable Model
    "model-process": "The executable state machine models every possible path through voter registration — from application to registered or denied.",
    "model-documents": "The document recognizer formally defines which documents satisfy the SAVE Act's proof-of-citizenship requirement.",
    "model-burden": "This 5-step executable chain derives the severity of the burden rather than assuming it, making the conclusion more defensible.",
    "model-hinge": "The interpretive fork is the key structural insight: the entire dispute reduces to how one statutory phrase is read.",
    "model-existentials": "Existential propositions prove that the affected class of voters is non-empty — real people are affected.",
    "model-anderson-burdick": "The encapsulated doctrinal standard ensures the Anderson-Burdick test is applied consistently.",
    # Derivations
    "deriv-denial": "Shows that under the SAVE Act, citizen-a's registration is denied — the denial is a logical consequence of the statute.",
    "deriv-lacks-docs": "Formally derives that the citizen has no qualifying document from the SAVE Act's list.",
    "deriv-burden-chain": "The burden derivation chain transforms raw facts into the legal conclusion that the burden is severe.",
    "deriv-alt-process": "This is where the two models diverge: the mandatory reading provides a path to registration; the discretionary reading does not.",
    "deriv-hinge-fork": "The interpretive hinge fork is the single point where the challenger and government models split. Everything above is shared.",
    # Theorems
    "thm-registered-implies-acceptance": "This pure structural theorem proves that registration must pass through an acceptance state. It depends on zero assumptions — genuine process verification.",
    "thm-denied-implies-denial": "The denial-side dual: reaching 'denied' requires passing through a denial-triggering state. Zero assumptions.",
    "thm-terminal-remains": "Once registered or denied, the outcome is permanent. This guarantees the state machine has no anomalous loops.",
    "thm-nonqualifying-no-proof": "If a citizen's documents are all nonqualifying, they cannot satisfy the documentary proof requirement. Zero assumptions.",
    "thm-pivot": "The most important structural theorem: the entire constitutional dispute reduces to a single predicate — valid-regulationp. If the regulation is valid, no conflict; if invalid, conflict.",
    "thm-full-burden": "Derives the full burden chain: lacking documents + cannot obtain + no alternative → severe burden → invalid regulation. Uses the executable defun chain.",
    "thm-invalid-enables": "If the regulation is not valid, the formal conflict condition is established. The bridge from burden analysis to constitutional conflict.",
    "thm-valid-negates": "If the regulation is valid, the government wins — no formal conflict exists. The government's main defense.",
    # Conclusions
    "pivot-valid-regulation": "This single predicate — valid-regulationp — is the constitutional pivot. It is not proved by ACL2; it is determined entirely by which assumptions the user selects.",
    "concl-challenger": "Under challenger assumptions (no-fault, material burden, discretionary reading, invalid regulation), ACL2 derives that a formal constitutional conflict exists.",
    "concl-government": "Under government assumptions (burden not severe, adequate alternative, mandatory reading, valid regulation), ACL2 derives that no formal constitutional conflict exists.",
}


def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def load_csv(path):
    rows = []
    with open(path, "r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)
    return rows


def scan_lisp_events(model_dir):
    """Scan model/*.lisp files for defthm, defaxiom, and defun-sk events."""
    import re
    books = []
    theorems_by_book = {}
    axioms_by_book = {}
    existentials = []

    # Build trace lookup: axiom_name -> {label, source_id, clause_text}
    trace_lookup = {}
    trace_path = model_dir.parent / "sources" / "clause_trace.csv"
    if trace_path.exists():
        with open(trace_path, "r", encoding="utf-8-sig") as f:
            reader = csv.DictReader(f)
            for row in reader:
                trace_lookup[row.get("axiom_name", "")] = {
                    "label": row.get("label", ""),
                    "source_id": row.get("source_id", ""),
                    "clause_text": row.get("clause_text", ""),
                }

    pat_defthm = re.compile(r'^\s*\(defthm\s+(\S+)', re.IGNORECASE)
    pat_defaxiom = re.compile(r'^\s*\(defaxiom\s+(\S+)', re.IGNORECASE)
    pat_defunsk = re.compile(r'^\s*\(defun-sk\s+(\S+)', re.IGNORECASE)

    # Classify books by whether they use :defaxioms-okp
    clean_books = {
        "federal_save_act_core", "federal_save_act_process",
        "federal_save_act_process_invariants",
        "federal_save_act_deep_process_invariants",
        "federal_save_act_document_proofs",
        "federal_save_act_consistency_check",
    }

    # Layer assignments for human-readable grouping
    book_layers = {
        "federal_save_act_core": 0,
        "federal_save_act_process": 0,
        "federal_save_act_facts": 1,
        "federal_save_act_hinge_common": 2,
        "federal_save_act_hinge_mandatory": 3,
        "federal_save_act_hinge_discretionary": 3,
        "federal_save_act_existentials": 4,
        "federal_save_act_burden_proofs": 4,
        "federal_save_act_doctrine_proofs": 4,
        "federal_save_act_model_consistency": 4,
        "federal_save_act_independence": 4,
        "federal_save_act_challenger_model": 4,
        "federal_save_act_government_model": 4,
        "federal_save_act_process_invariants": 5,
        "federal_save_act_deep_process_invariants": 5,
        "federal_save_act_document_proofs": 5,
        "federal_save_act_consistency_check": 6,
    }

    for lisp_file in sorted(model_dir.glob("*.lisp")):
        book_name = lisp_file.stem
        thms = []
        axms = []
        sks = []

        with open(lisp_file, "r", encoding="utf-8") as f:
            for line in f:
                m = pat_defthm.match(line)
                if m:
                    thms.append(m.group(1))
                m = pat_defaxiom.match(line)
                if m:
                    name = m.group(1)
                    trace_info = trace_lookup.get(name, {})
                    axms.append({
                        "name": name,
                        "label": trace_info.get("label", ""),
                        "source_id": trace_info.get("source_id", ""),
                        "clause_text": trace_info.get("clause_text", ""),
                    })
                m = pat_defunsk.match(line)
                if m:
                    sks.append(m.group(1))

        is_clean = book_name in clean_books
        layer = book_layers.get(book_name, -1)

        books.append({
            "name": book_name,
            "file": lisp_file.name,
            "layer": layer,
            "clean": is_clean,
            "theorems": len(thms),
            "axioms": len(axms),
            "existentials": len(sks),
        })

        if thms:
            theorems_by_book[book_name] = thms
        if axms:
            axioms_by_book[book_name] = axms
        if sks:
            existentials.extend([{"name": s, "book": book_name} for s in sks])

    return books, theorems_by_book, axioms_by_book, existentials


def build():
    # --- Load inputs ---
    graph = load_json(ROOT / "data" / "parsed" / "explorer_graph.json")
    ace = load_json(ROOT / "data" / "parsed" / "federal_save_act_ace.json")
    manifest = load_json(ROOT / "sources" / "source_manifest.json")
    trace_rows = load_csv(ROOT / "sources" / "clause_trace.csv")
    version = load_json(ROOT / "version.json")

    # --- Build meta ---
    meta = {
        "project": version.get("project", "federal_save_act"),
        "title": "Federal SAVE Act — Computational Amicus Explorer",
        "version": version.get("version", "unknown"),
        "books_certified": version.get("census", {}).get("books", 17),
        "theorems": version.get("census", {}).get("theorems", 126),
        "axioms": version.get("census", {}).get("axioms", 33),
        "defun_sk_existentials": version.get("census", {}).get("defun_sk", 4),
        "authoritative_sources": len(manifest.get("sources", [])),
        "trace_rows": len(trace_rows),
        "ace_statements": len(ace.get("ace_statements", [])),
        "repo_url": REPO_URL,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }

    # --- Scan .lisp files for audit details ---
    model_dir = ROOT / "model"
    books, theorems_by_book, axioms_by_book, existentials_list = scan_lisp_events(model_dir)

    audit_details = {
        "books": books,
        "theorems_by_book": theorems_by_book,
        "axioms_by_book": axioms_by_book,
        "existentials": existentials_list,
    }

    # --- Enrich nodes with ACE data and why_it_matters ---
    ace_by_id = {s["id"]: s for s in ace.get("ace_statements", [])}
    nodes = graph["nodes"]
    for node in nodes:
        # Attach ACE data if this node matches an ACE statement
        ace_id = node.get("ace_id")
        if ace_id and ace_id in ace_by_id:
            ace_entry = ace_by_id[ace_id]
            node["ace_text"] = ace_entry.get("ace_text", "")
            node["source_text"] = ace_entry.get("source_text", "")
            node["predicate_target"] = ace_entry.get("predicate_target", "")

        # Attach curated plain-English explanation
        nid = node["id"]
        if nid in WHY_IT_MATTERS:
            node["why_it_matters"] = WHY_IT_MATTERS[nid]

    # --- Validate edges ---
    node_ids = {n["id"] for n in nodes}
    edges = graph["edges"]
    errors = []
    for i, edge in enumerate(edges):
        if edge["from"] not in node_ids:
            errors.append(f"Edge {i}: 'from' node '{edge['from']}' not found")
        if edge["to"] not in node_ids:
            errors.append(f"Edge {i}: 'to' node '{edge['to']}' not found")

    if errors:
        print("ERRORS in explorer graph:")
        for e in errors:
            print(f"  {e}")
        sys.exit(1)

    # --- Assemble output ---
    output = {
        "meta": meta,
        "audit_details": audit_details,
        "layers": graph["layers"],
        "nodes": nodes,
        "edges": edges,
        "hypotheticals": graph["hypotheticals"],
    }

    # --- Write output ---
    out_dir = ROOT / "web" / "data"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "explorer.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    print(f"Built {out_path}")
    print(f"  {len(nodes)} nodes, {len(edges)} edges, {len(graph['hypotheticals'])} hypotheticals")
    print(f"  {meta['theorems']} theorems, {meta['axioms']} axioms, {meta['books_certified']} books")


if __name__ == "__main__":
    build()
