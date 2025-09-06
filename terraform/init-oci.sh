#!/bin/bash
# Quick OCI initialization for Semaphore templates
# Use this directly in Semaphore template commands

# Check if we need the full setup
if [ -z "$OCI_CLI_CONFIG_FILE" ] || [ ! -f "$OCI_CLI_CONFIG_FILE" ]; then
    # Run the full setup
    source ./scripts/oci-terraform-setup.sh
else
    echo "✓ OCI environment already configured"
    echo "  OCI_CLI_CONFIG_FILE=$OCI_CLI_CONFIG_FILE"
fi

# Quick validation
if [ -f "$OCI_CLI_CONFIG_FILE" ]; then
    echo "✓ Configuration valid"
else
    echo "❌ Configuration invalid - running full setup..."
    source ./scripts/oci-terraform-setup.sh
fi
