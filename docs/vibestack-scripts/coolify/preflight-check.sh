#!/bin/bash

# Coolify Preflight Check Wrapper
# This script calls the centralized OCI CLI preflight check

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OCI_DIR="$(cd "$SCRIPT_DIR/../oci" && pwd)"

echo "==================================="
echo "Coolify OCI CLI Preflight Check"
echo "==================================="
echo ""
echo "Using centralized preflight from: $OCI_DIR"
echo ""

# Call the centralized preflight script
if [ -f "$OCI_DIR/preflight-check.sh" ]; then
    bash "$OCI_DIR/preflight-check.sh" "$@"
else
    echo "❌ Error: Centralized preflight script not found at $OCI_DIR/preflight-check.sh"
    echo "Please ensure the /oci folder structure is properly set up."
    exit 1
fi