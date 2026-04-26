# Local Certification Guide

## Overview

This document explains how to clone, validate, and certify the Federal SAVE Act ACL2 proof development locally. The project uses `acl2 < file.lisp` (ACL2 admission and proof checking) rather than full `certify-book` certification with `.cert` file generation. All 126 theorems are admitted and proved (Q.E.D.) by ACL2; the project does not yet generate `.cert` artifacts.

> **Important distinction**: ACL2 admission (loading a file and checking all events) provides the same logical guarantees as `certify-book` — every `defthm` must be proved. The difference is operational: `certify-book` generates `.cert` files for dependency tracking, while `acl2< file.lisp` does not. Both methods produce Q.E.D. for every admitted theorem.

## Requirements

| Requirement | Tested Version |
|---|---|
| ACL2 | 8.5 (via `atwalter/acl2:latest` Docker image) |
| Docker | 24.x+ (for Docker-based certification) |
| Python | 3.10+ (for trace validation) |
| Git | 2.x+ |
| OS | Linux, macOS, Windows (via Docker) |

If you have ACL2 installed natively, you can run the books directly without Docker.

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

### 3. Run the full proof suite

```bash
# Linux / macOS (Docker)
./scripts/certify_all.sh

# Windows (PowerShell, Docker)
.\scripts\certify_all.ps1
```

**Expected output**: All 17 books report Q.E.D., zero FAILED, with a summary line.

### 4. Run a single book

```bash
# Docker
docker compose run --rm acl2 acl2 < federal_save_act_process_invariants.lisp

# Native ACL2
acl2 < federal_save_act_process_invariants.lisp
```

## Book Dependency Order

Books must be run in an order that respects `include-book` dependencies:

```
Layer 0 (no dependencies):
  federal_save_act_core.lisp

Layer 1 (depends on core):
  federal_save_act_facts.lisp
  federal_save_act_process.lisp
  federal_save_act_consistency_check.lisp

Layer 2 (depends on facts):
  federal_save_act_hinge_common.lisp
  federal_save_act_existentials.lisp
  federal_save_act_burden_proofs.lisp
  federal_save_act_doctrine_proofs.lisp
  federal_save_act_model_consistency.lisp
  federal_save_act_challenger_model.lisp
  federal_save_act_government_model.lisp

Layer 2 (depends on process):
  federal_save_act_process_invariants.lisp
  federal_save_act_document_proofs.lisp

Layer 3 (depends on hinge_common):
  federal_save_act_hinge_mandatory.lisp
  federal_save_act_hinge_discretionary.lisp

Layer 3 (depends on process_invariants):
  federal_save_act_deep_process_invariants.lisp

Layer 2 (depends on facts):
  federal_save_act_independence.lisp
```

Each book can be run independently (ACL2 loads its dependencies via `include-book`). The scripts run all books in a valid order.

## Known Warnings

- **`[Compiled file]` warnings**: ACL2 may warn about uncertified compiled files. This is expected when running `acl2 < file.lisp` instead of `certify-book`. It does not affect proof validity.
- **`[Non-rec]` warnings**: Some theorems trigger non-recursive rule warnings. These are cosmetic — the proofs are still valid.
- **`[Subsume]` warnings**: Some theorems subsume earlier rules. This is intentional in the proof architecture.
- **Exit code 1 from Docker**: The ACL2 session exits without `(good-bye)`, causing a non-zero exit code. The scripts handle this by checking for `FAILED` in the output rather than relying on exit codes.

## Troubleshooting

| Problem | Solution |
|---|---|
| `docker: command not found` | Install Docker Desktop or Docker Engine |
| `acl2: command not found` | Install ACL2 or use the Docker method |
| Python `ModuleNotFoundError` | Ensure Python 3.10+ is installed; the validator uses only stdlib |
| `include-book` fails | Run books in dependency order, or use the provided scripts |
| `FAILED` in ACL2 output | Report as an issue — all theorems should produce Q.E.D. |

## What "Certified" Means in This Project

When we say "all books certify," we mean:

1. Every `defthm` in every book is admitted by ACL2 with a Q.E.D. result.
2. Every `encapsulate` block's exported constraints are verified against local witnesses.
3. Every `defun` is admitted (guard verification, termination proof where applicable).
4. Every `defun-sk` Skolemization is admitted.
5. The trace validator confirms all `defaxiom` forms have source-trace entries.

We do **not** currently generate `.cert` files via `certify-book`. This is a known limitation that does not affect the logical validity of the proofs.
