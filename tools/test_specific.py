import urllib.request, urllib.parse, xml.etree.ElementTree as ET
tests = [
    "A n:user selects a n:empirical-assumption in a n:explorer.",
    "A n:user uses a n:explorer and selects a n:empirical-assumption.",
    "Somebody derives a n:conclusion from a n:respective-assumption-set.",
    "A n:conclusion follows from a n:respective-assumption-set.",
    "A n:respective-assumption-set entails a n:conclusion.",
    "A n:project makes a n:legal-pivot a:explicit. The n:legal-pivot is a:mechanically-checkable.",
]
for t in tests:
    url = "https://attempto.ifi.uzh.ch/service/ape?text=" + urllib.parse.quote(t) + "&cparaphrase=on"
    resp = urllib.request.urlopen(url, timeout=15)
    data = resp.read().decode()
    root = ET.fromstring(data)
    msgs = root.find("messages")
    errs = [m for m in (msgs.findall("message") if msgs is not None else []) if m.get("importance") == "error"]
    warns = [m for m in (msgs.findall("message") if msgs is not None else []) if m.get("importance") == "warning"]
    status = "FAIL" if errs else ("WARN" if warns else "CLEAN")
    print(f"{status}: {t}")
    for e in errs:
        print(f"  ERR: {e.get('value', '')[:80]}")
    for w in warns:
        print(f"  WARN: {w.get('value', '')[:80]}")
