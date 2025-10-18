#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

main() {
    uvicorn web:app --reload --host 0.0.0.0 --port 8000
}

main "$@"
