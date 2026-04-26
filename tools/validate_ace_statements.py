#!/usr/bin/env python3
"""
ACE Statement Validator — Checks all ace_text fields against the Attempto APE webservice.

Usage: python tools/validate_ace_statements.py [--fix]

  --fix   Update the JSON file in-place with APE results (ape_status, ape_error, notes).

API docs: https://attempto.ifi.uzh.ch/site/docs/ape_webservice.html
Endpoint: http://attempto.ifi.uzh.ch/ws/ape/apews.perl
"""

import json
import sys
import time
import urllib.request
import urllib.parse
import urllib.error
import xml.etree.ElementTree as ET
from pathlib import Path

# Fix Windows console encoding
if sys.stdout.encoding and sys.stdout.encoding.lower() != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
ACE_JSON = ROOT / "data" / "parsed" / "federal_save_act_ace.json"

APE_URL = "https://attempto.ifi.uzh.ch/service/ape"

# How long to wait between API calls to be polite to the server
DELAY_SECONDS = 1.5


def call_ape(ace_text, guess=True):
    """
    Call the Attempto APE webservice with a single ACE text.

    Returns a dict:
      {
        "success": bool,        # True if parsed without errors
        "drs": str or None,     # The DRS if successful
        "paraphrase": str or None,  # APE's paraphrase of the input
        "messages": [           # List of error/warning messages
          {"importance": "error"|"warning", "type": ..., "value": ..., "repair": ...}
        ],
        "duration": str,
        "raw_xml": str,
      }
    """
    params = {
        "text": ace_text,
        "cdrs": "on",
        "cdrspp": "on",
        "cparaphrase": "on",
        "ctokens": "on",
    }
    if guess:
        params["guess"] = "on"

    query = urllib.parse.urlencode(params)
    url = f"{APE_URL}?{query}"

    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "SAVE-Act-ACE-Validator/1.0",
            "Accept": "text/xml, application/xml",
        })
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read().decode("utf-8")
    except urllib.error.URLError as e:
        return {
            "success": False,
            "drs": None,
            "paraphrase": None,
            "messages": [{"importance": "error", "type": "network", "value": str(e), "repair": ""}],
            "duration": "",
            "raw_xml": "",
        }

    # Parse the XML response
    try:
        root = ET.fromstring(raw)
    except ET.ParseError as e:
        return {
            "success": False,
            "drs": None,
            "paraphrase": None,
            "messages": [{"importance": "error", "type": "xml", "value": f"XML parse error: {e}", "repair": ""}],
            "duration": "",
            "raw_xml": raw[:500],
        }

    # Extract components
    drs_el = root.find("drs")
    drs = drs_el.text.strip() if drs_el is not None and drs_el.text else None
    drspp_el = root.find("drspp")
    drspp = drspp_el.text.strip() if drspp_el is not None and drspp_el.text else None

    paraphrase_el = root.find("paraphrase")
    paraphrase = paraphrase_el.text.strip() if paraphrase_el is not None and paraphrase_el.text else None

    duration_el = root.find("duration")
    duration = ""
    if duration_el is not None:
        duration = f"tok={duration_el.get('tokenizer', '?')}s parse={duration_el.get('parser', '?')}s"

    messages = []
    msgs_el = root.find("messages")
    if msgs_el is not None:
        for msg in msgs_el.findall("message"):
            messages.append({
                "importance": msg.get("importance", ""),
                "type": msg.get("type", ""),
                "value": msg.get("value", ""),
                "repair": msg.get("repair", ""),
                "sentence": msg.get("sentence", ""),
                "token": msg.get("token", ""),
            })

    # Check for empty DRS (indicates failure)
    is_empty_drs = drs == "drs([], [])" or drs == "drs([],[])"
    has_errors = any(m["importance"] == "error" for m in messages)
    success = not is_empty_drs and not has_errors

    return {
        "success": success,
        "drs": drspp or drs,
        "paraphrase": paraphrase,
        "messages": messages,
        "duration": duration,
        "raw_xml": raw,
    }


def validate_all(fix=False):
    """Validate all ACE statements against the APE webservice."""
    data = json.loads(ACE_JSON.read_text(encoding="utf-8"))
    statements = data.get("ace_statements", [])

    print(f"{'='*70}")
    print(f"  ACE Statement Validator — Attempto APE Webservice")
    print(f"  File: {ACE_JSON.name}")
    print(f"  Statements: {len(statements)}")
    print(f"  Mode: {'FIX (will update JSON)' if fix else 'CHECK ONLY'}")
    print(f"{'='*70}\n")

    results = []
    passed = 0
    failed = 0
    warnings = 0

    for i, stmt in enumerate(statements):
        ace_id = stmt.get("id", f"stmt-{i}")
        ace_text = stmt.get("ace_text", "")

        if not ace_text:
            print(f"[{ace_id}] SKIP — no ace_text")
            continue

        # Multi-sentence texts: APE handles them natively
        print(f"[{ace_id}] Checking...")

        result = call_ape(ace_text)

        if result["success"]:
            passed += 1
            status = "PASS"
            status_icon = "✅"
            ape_status = "PASS"
            ape_error = None
        else:
            error_msgs = [m for m in result["messages"] if m["importance"] == "error"]
            warn_msgs = [m for m in result["messages"] if m["importance"] == "warning"]

            if error_msgs:
                failed += 1
                status = "FAIL"
                status_icon = "❌"
                ape_status = "FAIL"
                ape_error = "; ".join(m["value"] for m in error_msgs)
            elif warn_msgs:
                warnings += 1
                status = "WARN"
                status_icon = "⚠️"
                ape_status = "WARN"
                ape_error = "; ".join(m["value"] for m in warn_msgs)
            else:
                failed += 1
                status = "FAIL"
                status_icon = "❌"
                ape_status = "FAIL"
                ape_error = "Empty DRS returned (no specific error message)"

        print(f"  {status_icon} {status}")
        if result.get("paraphrase"):
            print(f"  Paraphrase: {result['paraphrase'][:120]}")
        if ape_error:
            print(f"  Error: {ape_error[:200]}")
        for msg in result.get("messages", []):
            if msg["repair"]:
                print(f"  Repair: {msg['repair'][:200]}")

        results.append({
            "id": ace_id,
            "status": ape_status,
            "error": ape_error,
            "paraphrase": result.get("paraphrase"),
            "drs": result.get("drs"),
            "messages": result.get("messages", []),
        })

        # Update the JSON entry if --fix
        if fix:
            stmt["ape_status"] = ape_status
            stmt["ape_error"] = ape_error
            if ape_status == "PASS":
                stmt["requires_human_review"] = False
                stmt["notes"] = f"APE validated. Paraphrase: {result.get('paraphrase', 'n/a')[:200]}"
            elif ape_status == "WARN":
                stmt["requires_human_review"] = True
                stmt["notes"] = f"APE warnings: {ape_error}"
            else:
                stmt["requires_human_review"] = True
                stmt["notes"] = f"APE error: {ape_error}"

        # Be polite to the server
        if i < len(statements) - 1:
            time.sleep(DELAY_SECONDS)

    # Summary
    print(f"\n{'='*70}")
    print(f"  RESULTS SUMMARY")
    print(f"{'='*70}")
    print(f"  Total:    {len(results)}")
    print(f"  Passed:   {passed} ✅")
    print(f"  Warnings: {warnings} ⚠️")
    print(f"  Failed:   {failed} ❌")
    print(f"{'='*70}")

    if failed > 0:
        print(f"\n  FAILED STATEMENTS:")
        for r in results:
            if r["status"] == "FAIL":
                print(f"    [{r['id']}] {r['error'][:100]}")

    # Write updated JSON if --fix
    if fix:
        ACE_JSON.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"\n  Updated: {ACE_JSON}")

    return failed


if __name__ == "__main__":
    fix_mode = "--fix" in sys.argv
    failures = validate_all(fix=fix_mode)
    sys.exit(1 if failures > 0 else 0)
