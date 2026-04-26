# Local Certification Guide

## Overview

This project supports **two levels** of ACL2 verification:

| Level | Command | Produces | What it verifies |
|---|---|---|---|
| **Batch admission** | `acl2 < file.lisp` | Console Q.E.D. output | Every event (defthm, defun, encapsulate) is admitted |
| **Full book certification** | `certify-book` | `.cert` file | All of the above + dependency tracking + portable verification |

Both levels provide the same logical guarantees — every `defthm` must be proved by ACL2's theorem prover. The difference is operational: `certify-book` additionally generates `.cert` artifacts that enable ACL2's dependency checker and allow other tools to verify the proof chain.

### The defaxiom constraint

ACL2 refuses to `certify-book` any book that contains `defaxiom` unless the `:defaxioms-okp t` flag is passed. This is ACL2's built-in warning that `defaxiom` introduces unverified assumptions.

In this project:
- **6 books** are certified **clean** (no defaxiom in the book or its dependency chain)
- **5 books** contain `defaxiom` directly — certified with `:defaxioms-okp t`
- **6 books** inherit defaxiom through `include-book` of `federal_save_act_facts.lisp` — certified with `:defaxioms-okp t`

All 33 defaxioms are source-traced and classified — see `reports/axiom_pressure_report.md`.

## Requirements

| Requirement | Tested Version |
|---|---|
| ACL2 | 8.5 (via `atwalter/acl2:latest` Docker image) |
| Docker | 24.x+ (for Docker-based certification) |
| Python | 3.10+ (for trace validation) |
| Git | 2.x+ |
| OS | Linux, macOS, Windows (via Docker) |

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/f-pound/federal_save_act.git
cd federal_save_act
```

### 2. Validate source traces

```bash
# Linux / macOS
PROJECT_ROOT=. python3 tools/validate_trace.py

# Windows (PowerShell)
$env:PROJECT_ROOT = "."; python tools/validate_trace.py
```

**Expected output**: `RESULT: 0 errors, 0 warnings — PASS`

### 3. Run full book certification (certify-book)

This is the **recommended** verification method. It produces `.cert` files.

```bash
# Linux / macOS (Docker)
./scripts/certify_books.sh

# Windows (PowerShell, Docker)
powershell -ExecutionPolicy Bypass -File .\scripts\certify_books.ps1
```

**Expected output**: All 17 books report `CERT`, with logs saved to `logs/certify/`.

### 4. Run batch admission (alternative)

If you prefer the simpler batch-run approach (no `.cert` files generated):

```bash
# Linux / macOS (Docker)
./scripts/certify_all.sh

# Windows (PowerShell, Docker)
powershell -ExecutionPolicy Bypass -File .\scripts\certify_all.ps1
```

**Expected output**: All 14 proof books report Q.E.D., with logs saved to `logs/`.

### 5. Run a single book

```bash
# certify-book (Docker)
echo '(certify-book "federal_save_act_core" ?)' | docker compose run --rm acl2 acl2

# certify-book for defaxiom books
echo '(certify-book "federal_save_act_facts" ? nil :defaxioms-okp t)' | docker compose run --rm acl2 acl2

# Batch admission (Docker)
docker compose run --rm acl2 acl2 < federal_save_act_process_invariants.lisp

# Native ACL2
acl2 < federal_save_act_process_invariants.lisp
```

## Book Classification

### Clean books (no defaxiom — standard certify-book)

| Book | Layer | certify-book command |
|---|---|---|
| `federal_save_act_core` | 0 | `(certify-book "federal_save_act_core" ?)` |
| `federal_save_act_process` | 1 | `(certify-book "federal_save_act_process" ?)` |
| `federal_save_act_consistency_check` | 1 | `(certify-book "federal_save_act_consistency_check" ?)` |
| `federal_save_act_process_invariants` | 2 | `(certify-book "federal_save_act_process_invariants" ?)` |
| `federal_save_act_document_proofs` | 2 | `(certify-book "federal_save_act_document_proofs" ?)` |
| `federal_save_act_deep_process_invariants` | 3 | `(certify-book "federal_save_act_deep_process_invariants" ?)` |

### Defaxiom books (require :defaxioms-okp t)

| Book | Layer | Contains defaxiom | Reason |
|---|---|---|---|
| `federal_save_act_facts` | 1 | **Yes** (3 text facts) | Source-traced statutory text |
| `federal_save_act_hinge_mandatory` | 3 | **Yes** (bridge rules) | Mandatory reading semantics |
| `federal_save_act_hinge_discretionary` | 3 | **Yes** (bridge rules) | Discretionary reading semantics |
| `federal_save_act_challenger_model` | 2 | **Yes** (scenario + interpretive) | Challenger party assumptions |
| `federal_save_act_government_model` | 2 | **Yes** (scenario + interpretive) | Government party assumptions |

### Inherited defaxiom (include facts.lisp — require :defaxioms-okp t)

| Book | Layer | Own defaxiom | Inherited from |
|---|---|---|---|
| `federal_save_act_hinge_common` | 2 | No | facts |
| `federal_save_act_existentials` | 2 | No | facts |
| `federal_save_act_burden_proofs` | 2 | No | facts |
| `federal_save_act_doctrine_proofs` | 2 | No | facts |
| `federal_save_act_model_consistency` | 2 | No | facts |
| `federal_save_act_independence` | 2 | No | facts |

## Source-Traced Trusted Base

Every `defaxiom` in the project is:
1. **Classified** by type (SCENARIO_FACT, EMPIRICAL_ASSUMPTION, BRIDGE_RULE, etc.)
2. **Traced** to a specific clause in a public legal document
3. **Inventoried** in `reports/axiom_pressure_report.md`
4. **Machine-validated** by `tools/validate_trace.py`

The 33 defaxioms break down as:
- 14 scenario facts (low risk — stipulated ground facts about citizen-a)
- 5 bridge rules (low risk — structural connectors)
- 6 government interpretive assumptions (medium risk)
- 3 empirical assumptions (high risk — contestable)
- 2 interpretive assumptions (medium risk — hinge semantics)
- 2 doctrinal rules (medium risk — case law holdings)
- 1 challenger interpretive assumption (medium risk)

See `reports/certification_status.md` for the full certification matrix.

## .cert Files

`.cert` files are generated during certification but **not committed** to the repository. They are:
- Generated by CI on every push (see `.github/workflows/acl2-proofs.yml`)
- Generated locally by `scripts/certify_books.sh` or `.ps1`
- Listed in `.gitignore`

This is standard practice for ACL2 projects — `.cert` files are build artifacts, not source files.

## Known Warnings

- **`[Defaxioms]` warning**: ACL2 warns when certifying books with defaxiom. This is expected — the `:defaxioms-okp t` flag acknowledges the warning.
- **`[Compiled file]` warning**: ACL2 may warn about compiled file versions. Does not affect proof validity.
- **`[Non-rec]` warning**: Some theorems trigger non-recursive rule warnings. Cosmetic only.

## Troubleshooting

| Problem | Solution |
|---|---|
| `docker: command not found` | Install Docker Desktop or Docker Engine |
| `acl2: command not found` | Install ACL2 or use the Docker method |
| `DEFAXIOM events` error | Use `:defaxioms-okp t` flag (see book classification above) |
| `include-book` fails | Certify dependency books first (use the scripts for correct ordering) |
| Python `ModuleNotFoundError` | Ensure Python 3.10+ is installed; the validator uses only stdlib |
| `FAILED` in output | Report as an issue — all theorems should produce Q.E.D. |
