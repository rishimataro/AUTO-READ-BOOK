#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

main() {
    curl -X POST "http://127.0.0.1:8000/document_scan" \
        -H "accept: application/zip" \
        -F "file=@Untitled.jpg" \
        --output pages.zip
}

main "$@"
