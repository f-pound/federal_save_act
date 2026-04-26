"""
Test ACE conversions for README.md prose paragraphs — Final Round.
"""
import urllib.request, urllib.parse, xml.etree.ElementTree as ET, time

def check(label, text):
    url = "https://attempto.ifi.uzh.ch/service/ape?text=" + urllib.parse.quote(text) + "&cdrspp=on&cparaphrase=on"
    resp = urllib.request.urlopen(url, timeout=30)
    data = resp.read().decode()
    root = ET.fromstring(data)
    msgs = root.find("messages")
    all_msgs = [m for m in (msgs.findall("message") if msgs is not None else [])]
    errs = [m for m in all_msgs if m.get("importance") == "error"]
    warns = [m for m in all_msgs if m.get("importance") == "warning"]
    status = "FAIL" if errs else ("WARN" if warns else "CLEAN")
    print(f"{status} {label}")
    for e in errs:
        print(f"  ERR: {e.get('value', '')[:140]}")
    for w in warns:
        print(f"  WARN: {w.get('value', '')[:100]}")
    time.sleep(1)
    return status

# Line 3
p3 = (
    "A n:project v:stress-tests a n:federal-statute. "
    "The n:federal-statute is a n:Safeguard-American-Voter-Eligibility-Act. "
    "The n:federal-statute requires a n:documentary-proof-of-citizenship for a n:voter-registration in a n:federal-election."
)

# Line 5
p5 = (
    "A n:project uses a n:framework. "
    "The n:framework separates a n:text-derived-statutory-fact from a n:interpretive-assumption. "
    "The n:project runs a n:competing-ACL2-proof-obligation. "
    "The n:competing-ACL2-proof-obligation identifies a n:controlling-assumption for a n:constitutional-outcome."
)

# Line 11
p11 = (
    "If a n:law-status is established and a n:qualified-voter-status is established and a n:protected-right is established and a n:registration-transaction is established and a n:statutory-denial is established then a n:formal-pivot remains. "
    "A n:clean-book proves that a n:state-machine has a n:coherent-registration-path and a n:coherent-denial-path. "
    "The n:state-machine includes a n:alternative-approval-path in the n:coherent-registration-path. "
    "A n:separate-interpretive-assumption determines that a n:statute requires a n:approval under the n:alternative-approval-path."
)

# Line 13
p13 = (
    "A n:government-model has a n:no-conflict-theorem. "
    "The n:no-conflict-theorem depends on a n:scenario-fact and a n:doctrinal-assumption and a n:interpretive-assumption and a n:empirical-assumption and a n:bridge-rule. "
    "A n:legal-defense-factor is a n:subset of the n:scenario-fact and the n:doctrinal-assumption and the n:interpretive-assumption."
)

# Line 15
p15 = (
    "A n:government-model formalizes a n:Crawford-Anderson-Burdick-defense. "
    "If a n:doctrinal-premise is accepted and a n:interpretive-premise is accepted and a n:empirical-premise is accepted then a n:no-conflict-theorem follows."
)

# Line 17
p17 = (
    "A n:certified-ACL2-book does not prove that a n:statute is constitutional. "
    "The n:certified-ACL2-book does not prove that the n:statute is unconstitutional. "
    "If a n:explicitly-stated-assumption holds then a n:government-model entails a n:no-conflict and a n:challenger-model entails a n:conflict. "
    "A n:clean-book proves a n:process-invariant and a n:document-list-invariant with no n:trusted-legal-assumption. "
    "A n:defaxiom-chain-book introduces a n:statutory-assumption and a n:empirical-assumption and a n:doctrinal-assumption and a n:interpretive-assumption. "
    "A n:project makes a n:legal-pivot a:explicit. The n:legal-pivot is a:mechanically-checkable."
)

# Line 21
p21 = (
    "A n:project uses a n:hybrid-architecture. "
    "The n:hybrid-architecture uses a n:encapsulate-technique with a n:local-witness-function for a n:interpretive-predicate and a n:doctrinal-standard. "
    "The n:hybrid-architecture uses a n:defaxiom-technique for a n:text-derived-fact and a n:scenario-ground-truth. "
    "The n:hybrid-architecture uses a n:executable-defun-chain for a n:derived-burden-conclusion."
)

# Line 53
p53 = (
    "A n:user uses a n:explorer and selects a n:empirical-assumption and a n:interpretive-assumption and a n:doctrinal-assumption. "
    "The n:user sees which n:proof-paths and which n:conditional-conclusions are supported. "
    "The n:explorer visualizes a n:certified-ACL2-proof-dependency across 6 n:layers."
)

# Line 81
p81 = (
    "A n:primary-interpretive-hinge exists. "
    "If a n:alternative-attestation-process provides a n:constitutionally-adequate-safety-valve then a n:constitutional-outcome changes."
)

# Line 233-235
p233 = (
    "A n:project uses a n:recursive-function and a n:event-trace and a n:induction-over-lists and a n:encapsulate-technique and a n:defun-sk-Skolemization and a n:CI-certified-theorem and a n:machine-checkable-source-traceability. "
    "The n:project is not as complex as a n:major-ACL2-industrial-proof. "
    "A n:primary-value is in a n:legal-modeling-architecture."
)

# Line 249
p249 = (
    "A n:project has a n:method. "
    "A n:future-project may generalize the n:method into a n:computational-amicus-brief. "
    "The n:project concerns a n:Federal-SAVE-Act."
)

# Line 272
p272 = (
    "A n:challenger argues that a n:documentary-proof-requirement is a n:undue-burden on a n:citizen that lacks a n:qualifying-document. "
    "A n:government argues that the n:documentary-proof-requirement is a n:valid-regulation with a n:adequate-alternative-process. "
    "A n:respective-assumption-set entails a n:conclusion."
)

# Line 280
p280 = (
    "A n:project is a n:legal-analysis-tool. "
    "The n:project is not a n:legal-advice. "
    "A n:ACL2-model does not decide a n:constitutionality. "
    "The n:ACL2-model identifies a n:proof-obligation and a n:assumption."
)

tests = {
    "L3-project-desc": p3,
    "L5-framework": p5,
    "L11-proves-p1": p11,
    "L13-govt-model": p13,
    "L15-crawford": p15,
    "L17-certified": p17,
    "L21-architecture": p21,
    "L53-explorer": p53,
    "L81-hinge": p81,
    "L233-complexity": p233,
    "L249-future": p249,
    "L272-challenger": p272,
    "L280-disclaimer": p280,
}

passed = 0
failed = 0
warned = 0
for k, v in tests.items():
    s = check(k, v)
    if s == "CLEAN": passed += 1
    elif s == "WARN": warned += 1
    else: failed += 1

print(f"\n{'='*50}")
print(f"CLEAN: {passed}  WARN: {warned}  FAIL: {failed}  TOTAL: {len(tests)}")
