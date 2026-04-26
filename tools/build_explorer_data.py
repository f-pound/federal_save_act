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
