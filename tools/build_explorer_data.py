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

    # --- Enrich nodes with ACE data ---
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
