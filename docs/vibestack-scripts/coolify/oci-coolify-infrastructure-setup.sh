#!/bin/bash

# OCI Infrastructure Setup Script for Coolify Self-Host
# This is a wrapper that calls the centralized OCI infrastructure setup script
# Located in the /oci folder for DRY principle compliance

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OCI_DIR="$(cd "$SCRIPT_DIR/../oci" && pwd)"

echo "🚀 Coolify Infrastructure Setup (using centralized OCI scripts)"
echo "==============================================================="
echo ""

# Check if centralized script exists
if [ ! -f "$OCI_DIR/oci-infrastructure-setup.sh" ]; then
    echo "❌ Error: Centralized infrastructure script not found at $OCI_DIR/oci-infrastructure-setup.sh"
    exit 1
fi

# Check if .env exists in oci directory
if [ ! -f "$OCI_DIR/.env" ]; then
    echo "❌ Error: .env file not found in $OCI_DIR"
    echo "Please configure $OCI_DIR/.env first"
    exit 1
fi

# Call the centralized infrastructure setup script with 'coolify' parameter
echo "🔧 Calling centralized OCI infrastructure setup for Coolify..."
echo ""
bash "$OCI_DIR/oci-infrastructure-setup.sh" coolify

# Check if the script completed successfully
if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Coolify infrastructure setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Run the Coolify installation script:"
    echo "     bash $SCRIPT_DIR/coolify-installation.sh"
    echo ""
    echo "  2. Set up Cloudflare tunnel (optional):"
    echo "     bash $SCRIPT_DIR/coolify-cloudflare-tunnel-setup.sh"
    echo ""
else
    echo ""
    echo "❌ Infrastructure setup failed. Please check the error messages above."
    exit 1
fi