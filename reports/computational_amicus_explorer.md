# Computational Amicus Explorer

## Purpose

The Computational Amicus Explorer is a browser-based visual dependency tool that lets users interactively explore the Federal SAVE Act ACL2 proof-dependency graph.

**What it does:**
- Visualizes the certified ACL2 proof structure across 6 conceptual layers
- Lets users toggle empirical, interpretive, and doctrinal assumptions
- Shows which conditional conclusions remain supported under selected assumptions
- Provides detailed metadata for every node (source reference, ACL2 event, book, axiom count)

**What it does NOT do:**
- Run ACL2 live or create new proofs
- Decide the legal merits or constitutionality of the SAVE Act
- Replace ACL2 certification
- Call an LLM or external web service

## How to Run

```bash
python tools/serve_explorer.py
# Opens http://127.0.0.1:8000
```

Or manually:

```bash
python tools/build_explorer_data.py
python -m http.server 8000 -d web
```

## Data Sources

The explorer is generated from these repository artifacts:

| Source | Content |
|---|---|
| `data/parsed/explorer_graph.json` | Curated dependency graph (nodes, edges, hypotheticals) |
| `data/parsed/federal_save_act_ace.json` | 13 ACE controlled-English propositions with predicate targets |
| `sources/source_manifest.json` | 21 authoritative sources with citations |
| `sources/clause_trace.csv` | 38-row axiom→source traceability map |
| `version.json` | Project metadata and audit metrics |

## Graph Layers

| Layer | Content |
|---|---|
| 1. Sources & Traceability | Legal sources, constitutional provisions, case law, traceability artifacts |
| 2. Formalization & Assumptions | Scenario facts, text facts, empirical/interpretive/doctrinal assumptions |
| 3. Executable ACL2 Model | State machine, document model, burden chain, hinge fork, existentials |
| 4. Derivations | Denial, lacks-documents, burden chain, alternative-process, hinge fork |
| 5. Representative Theorems | Axiom-free structural theorems + assumption-dependent legal-consequence theorems |
| 6. Final Conclusions | valid-regulationp pivot + Challenger CONFLICT / Government NO CONFLICT |

## How Hypotheticals Work

Each assumption toggle controls one or more axiom nodes in the graph. When an assumption is unchecked:

1. The controlled axiom node is dimmed (grayed out)
2. Any downstream node whose **all** support edges come from dimmed nodes is also dimmed
3. Final conclusion status badges update:
   - **Supported** — all path-specific hypotheticals are active
   - **Unsupported** — one or more path-specific hypotheticals are off
   - **Contested** — some direct supporters are dimmed

Axiom-free structural theorems (0 axioms) are never dimmed because they don't depend on assumptions.

## High-Risk Empirical Assumptions

Three assumptions are marked HIGH RISK because they are:
- Contestable between the parties
- Not proved by ACL2 (trusted base)
- Outcome-influencing (if toggled, the conclusion changes)

| Assumption | Path | Description |
|---|---|---|
| Citizen lacks documents through no fault | Challenger | citizen-a lacks qualifying documents through no personal fault |
| Obtaining documents is materially burdensome | Challenger | Obtaining qualifying documents imposes a material burden |
| Government: burden is not severe | Government | The burden of obtaining documents is not severe |

## The Mandatory / Discretionary Hinge Fork

The SAVE Act § 8(j)(2)(A) creates a critical ambiguity: does "sufficiently established" mean:

- **Mandatory reading** — the official must approve if evidence is adequate → guaranteed registration path (supports government)
- **Discretionary reading** — the official has discretion → possible denial even with evidence (supports challenger)

These are mutually exclusive interpretations. If both are selected, the explorer shows a warning.

## Axiom-Free Theorem Labels

Four structural theorems carry the "0 AXIOMS" badge:

| Theorem | Plain English |
|---|---|
| `registered-implies-prior-acceptance-path` | Registration requires a prior acceptance path |
| `denied-implies-prior-denial-path` | Denial requires a prior denial path |
| `terminal-state-remains-terminal` | Terminal states are irreversible |
| `all-nonqualifying-implies-no-documentary-proof` | Nonqualifying documents cannot satisfy documentary proof |

These are pure logical consequences of the executable model — they require no assumptions.

## Future Improvements

- SVG connector arrows between nodes showing dependency flow
- Keyboard navigation (arrow keys to move between nodes)
- URL-encoded state (shareable links for specific assumption configurations)
- GitHub Pages deployment for public access
- Integration with ACE parser for live controlled-English input
