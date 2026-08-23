#!/usr/bin/env bash
# certify_books.sh — certify every book under model/ in include order.
# Delegates to tools/certify.py (project-independent): discovers books,
# orders them by include-book, sets :defaxioms-okp from the include closure,
# and runs the generator / stability / audit pre-checks first.
# Runner: $ACL2_CMD, else native `acl2`, else docker compose.
set -euo pipefail
cd "$(dirname "$0")/.."
exec python3 tools/certify.py "$@"
