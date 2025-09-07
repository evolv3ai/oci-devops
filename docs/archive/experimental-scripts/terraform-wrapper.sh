#!/bin/bash
# Terraform Wrapper for Semaphore
# Ensures OCI environment is properly configured before running Terraform

set -e

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the OCI setup script
if [ -f "$SCRIPT_DIR/oci-terraform-setup.sh" ]; then
    source "$SCRIPT_DIR/oci-terraform-setup.sh"
elif [ -f "./scripts/oci-terraform-setup.sh" ]; then
    source ./scripts/oci-terraform-setup.sh
elif [ -f "../scripts/oci-terraform-setup.sh" ]; then
    source ../scripts/oci-terraform-setup.sh
else
    echo "❌ ERROR: Cannot find oci-terraform-setup.sh"
    echo "   Please ensure the setup script exists in the scripts directory"
    exit 1
fi

# Now run Terraform with all arguments passed through
echo "Executing: terraform $@"
terraform "$@"
