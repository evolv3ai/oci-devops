# Terraform Workspace Configuration for Semaphore

## Overview
This Terraform configuration uses workspaces to manage different environments with a single codebase.

## Available Workspaces

1. **test-vcn-only**
   - Purpose: Test OCI authentication and basic VCN creation
   - Deploys: VCN, Subnets, Internet Gateway only
   - No compute resources
   - CIDR: 10.99.0.0/16

2. **production**
   - Purpose: Production Semaphore deployment
   - Deploys: Full infrastructure (VCN + Compute)
   - CIDR: 10.0.0.0/16

3. **dev**
   - Purpose: Development environment
   - Deploys: Full infrastructure (VCN + Compute)
   - CIDR: 10.1.0.0/16

## Usage

### Local Terraform Commands
```bash
# List workspaces
terraform workspace list

# Switch workspace
terraform workspace select test-vcn-only

# Plan for current workspace
terraform plan

# Apply for current workspace
terraform apply
```

### Semaphore UI Configuration

1. **Create Template**
   - Set subdirectory path to: `terraform` (NOT `terraform/test-vcn-only.tf`)
   - Select workspace from dropdown: `test-vcn-only`, `production`, or `dev`

2. **Variable Group (oci-terra-vars)**
   Configure your OCI credentials:
   ```json
   {
     "TF_VAR_compartment_id": "ocid1.compartment.oc1...",
     "TF_VAR_tenancy_ocid": "ocid1.tenancy.oc1...",
     "TF_VAR_user_ocid": "ocid1.user.oc1...",
     "TF_VAR_fingerprint": "xx:xx:xx:xx...",
     "TF_VAR_private_key_path": "/path/to/key.pem",
     "TF_VAR_ssh_public_key": "ssh-rsa AAAA..."
   }
   ```

## Workspace Configuration Logic

The configuration is controlled by `workspace-config.tf` which defines:
- Whether to deploy VCN (`deploy_vcn`)
- Whether to deploy compute resources (`deploy_compute`)
- VCN CIDR blocks per workspace
- Resource naming conventions

## File Structure

```
terraform/
├── main.tf                 # Provider configuration
├── variables.tf            # Variable definitions
├── workspace-config.tf     # Workspace-specific settings
├── vcn.tf                  # VCN resources (conditional)
├── compute.tf              # Compute resources (conditional)
├── outputs.tf              # Workspace-aware outputs
├── user-data.sh            # Instance bootstrap script
└── test-vcn-only.tf.disabled  # Original test file (disabled)
```

## Testing Authentication

To test OCI authentication without deploying full infrastructure:
1. Select workspace: `terraform workspace select test-vcn-only`
2. Run: `terraform apply`
3. This will only create a VCN to validate authentication

## Cleanup

To destroy resources in a specific workspace:
```bash
terraform workspace select <workspace-name>
terraform destroy
```

## Notes
- Each workspace maintains separate state
- Resources are tagged with workspace name
- VCN CIDR blocks are different per workspace to avoid conflicts
- The `test-vcn-only` workspace is perfect for validating Semaphore's Terraform integration