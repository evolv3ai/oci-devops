#!/bin/bash

# Coolify Environment Validation Wrapper
# This script calls the centralized validation with coolify parameter

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OCI_DIR="$(cd "$SCRIPT_DIR/../oci" && pwd)"

echo "==================================="
echo "Coolify Environment Validation"
echo "==================================="
echo ""
echo "Using centralized validation from: $OCI_DIR"
echo ""

# Call the centralized validation script with coolify parameter
if [ -f "$OCI_DIR/validate-env.sh" ]; then
    bash "$OCI_DIR/validate-env.sh" coolify "$@"
else
    echo "❌ Error: Centralized validation script not found at $OCI_DIR/validate-env.sh"
    echo "Please ensure the /oci folder structure is properly set up."
    exit 1
fi