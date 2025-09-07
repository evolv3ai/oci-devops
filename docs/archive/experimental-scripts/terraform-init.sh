#!/bin/bash
# Terraform initialization script for Semaphore
# Use this with Terraform template type

set -e

echo "================================================"
echo "Terraform OCI Initialization"
echo "================================================"

# Only set environment if not already set by Terraform template
if [ -z "$OCI_CLI_CONFIG_FILE" ]; then
    # Check for OCI config in standard locations
    if [ -f "/oci/config" ]; then
        export OCI_CLI_CONFIG_FILE="/oci/config"
    elif [ -f "/home/semaphore/.oci/config" ]; then
        export OCI_CLI_CONFIG_FILE="/home/semaphore/.oci/config"
    fi
fi

# If private key path is set as TF_VAR, export for OCI
if [ -n "$TF_VAR_private_key_path" ]; then
    export OCI_PRIVATE_KEY_PATH="$TF_VAR_private_key_path"
fi

# Show configuration
echo "OCI Config: ${OCI_CLI_CONFIG_FILE:-default}"
echo "Profile: ${OCI_CONFIG_PROFILE:-DEFAULT}"

# Terraform will handle the rest
echo "Ready for Terraform execution"
echo "================================================"
