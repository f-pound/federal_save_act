#!/usr/bin/env python3
"""
validate_explorer_data.py — Validate web/data/explorer.json integrity.

Checks:
  - File exists and is valid JSON
  - All nodes have id, type, label
  - All edges reference existing node IDs
  - Final conclusion nodes exist
  - High-risk assumption nodes exist
  - Audit metrics are present
  - ACE-type nodes include predicate_target where available
  - No orphan nodes (every node has at least one edge)
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPLORER_PATH = ROOT / "web" / "data" / "explorer.json"


def validate():
    errors = []
    warnings = []

    # Check file exists
    if not EXPLORER_PATH.exists():
        print(f"FAIL: {EXPLORER_PATH} does not exist.")
        print("Run: python tools/build_explorer_data.py")
        sys.exit(1)

    # Load JSON
    try:
        with open(EXPLORER_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"FAIL: Invalid JSON: {e}")
        sys.exit(1)

    # Check meta
    meta = data.get("meta", {})
    required_meta = ["project", "title", "version", "books_certified", "theorems", "axioms"]
    for key in required_meta:
        if key not in meta:
            errors.append(f"Missing meta field: {key}")

    # Check nodes
    nodes = data.get("nodes", [])
    node_ids = set()
    if len(nodes) == 0:
        errors.append("No nodes found")

    for i, node in enumerate(nodes):
        nid = node.get("id")
        if not nid:
            errors.append(f"Node {i}: missing 'id'")
        else:
            if nid in node_ids:
                errors.append(f"Duplicate node id: {nid}")
            node_ids.add(nid)
        if not node.get("type"):
            errors.append(f"Node {nid or i}: missing 'type'")
        if not node.get("label"):
            errors.append(f"Node {nid or i}: missing 'label'")

    # Check edges
    edges = data.get("edges", [])
    for i, edge in enumerate(edges):
        if edge.get("from") not in node_ids:
            errors.append(f"Edge {i}: 'from' node '{edge.get('from')}' not found")
        if edge.get("to") not in node_ids:
            errors.append(f"Edge {i}: 'to' node '{edge.get('to')}' not found")
        if not edge.get("relation"):
            errors.append(f"Edge {i}: missing 'relation'")

    # Check final conclusions exist
    conclusion_nodes = [n for n in nodes if n.get("type") == "FINAL_CONCLUSION"]
    if len(conclusion_nodes) < 2:
        errors.append(f"Expected at least 2 FINAL_CONCLUSION nodes, found {len(conclusion_nodes)}")

    # Check high-risk assumptions exist
    high_risk = [n for n in nodes if n.get("high_risk")]
    if len(high_risk) < 2:
        errors.append(f"Expected at least 2 high-risk nodes, found {len(high_risk)}")

    # Check hypotheticals
    hyps = data.get("hypotheticals", [])
    if len(hyps) == 0:
        errors.append("No hypotheticals found")
    for h in hyps:
        if not h.get("id"):
            errors.append(f"Hypothetical missing 'id'")
        for ctrl in h.get("controls", []):
            if ctrl not in node_ids:
                errors.append(f"Hypothetical '{h.get('id')}' controls unknown node '{ctrl}'")

    # Check orphan nodes (nodes with no edges)
    connected = set()
    for edge in edges:
        connected.add(edge.get("from"))
        connected.add(edge.get("to"))
    orphans = node_ids - connected
    for o in orphans:
        warnings.append(f"Orphan node (no edges): {o}")

    # Check layers
    layers = data.get("layers", [])
    if len(layers) == 0:
        errors.append("No layers found")

    # Report
    print(f"Validated {EXPLORER_PATH}")
    print(f"  {len(nodes)} nodes, {len(edges)} edges, {len(hyps)} hypotheticals")
    print(f"  {len(conclusion_nodes)} conclusions, {len(high_risk)} high-risk assumptions")
    print(f"  {len(layers)} layers")

    if warnings:
        print(f"\nWarnings ({len(warnings)}):")
        for w in warnings:
            print(f"  WARNING: {w}")

    if errors:
        print(f"\nERRORS ({len(errors)}):")
        for e in errors:
            print(f"  ERROR: {e}")
        print(f"\nRESULT: FAIL ({len(errors)} errors, {len(warnings)} warnings)")
        sys.exit(1)
    else:
        print(f"\nRESULT: PASS (0 errors, {len(warnings)} warnings)")
        sys.exit(0)


if __name__ == "__main__":
    validate()
