# Semaphore Template Types: Terraform vs Shell/Bash

## The Issue

Your OCI config validation is failing because of the difference between Semaphore template types:

1. **Terraform Template Type**: 
   - Automatically handles Terraform environment
   - Expects TF_VAR_ prefixed variables
   - Has built-in Terraform binary
   - Manages working directory

2. **Shell/Bash Template Type**:
   - Runs raw shell scripts
   - Needs explicit environment setup
   - Must handle all configuration manually
   - Requires Terraform to be installed

## Your Current Situation

- **What's Working**: OCI config is mounted at `/oci/config` with all fields populated
- **What's Failing**: The bash script validation can't properly parse the config file
- **Root Cause**: The grep/awk commands in the script aren't correctly extracting fields from the Windows-formatted config

## Recommended Solutions

### Solution 1: Use Terraform Template Type (BEST)

Keep your existing Terraform template configuration and just add a minimal init script:

**Template Configuration:**
- Type: `terraform`
- Playbook: `terraform/`
- Arguments: `["-auto-approve"]`
- Command: (leave empty or add init script)

**Optional Pre-Command:**
```bash
# Only if needed for path fixing
export OCI_CLI_CONFIG_FILE=/oci/config
```

**Variable Group (with TF_VAR_ prefix):**
```
TF_VAR_tenancy_ocid=ocid1.tenancy.oc1...
TF_VAR_user_ocid=ocid1.user.oc1...
TF_VAR_fingerprint=2b:d5:03:cf:b2...
TF_VAR_region=us-ashburn-1
TF_VAR_compartment_id=ocid1.compartment.oc1...
TF_VAR_ssh_public_key=ssh-rsa AAAAB3...
```

### Solution 2: Fix Shell Template (More Complex)

If you must use Shell/Bash template:

**Template Configuration:**
- Type: `shell` or `bash`
- Command:
```bash
#!/bin/bash
# Export OCI config location
export OCI_CLI_CONFIG_FILE=/oci/config

# Export Terraform variables directly from Semaphore variables
export TF_VAR_tenancy_ocid="${tenancy_ocid}"
export TF_VAR_user_ocid="${user_ocid}"
export TF_VAR_fingerprint="${fingerprint}"
export TF_VAR_region="${region}"
export TF_VAR_compartment_id="${compartment_id}"
export TF_VAR_ssh_public_key="${ssh_public_key}"

# Navigate to Terraform directory
cd terraform/

# Run Terraform
terraform init -input=false
terraform plan -input=false
terraform apply -auto-approve
```

**Variable Group (without TF_VAR_ prefix for shell):**
```
tenancy_ocid=ocid1.tenancy.oc1...
user_ocid=ocid1.user.oc1...
fingerprint=2b:d5:03:cf:b2...
region=us-ashburn-1
compartment_id=ocid1.compartment.oc1...
ssh_public_key=ssh-rsa AAAAB3...
```

### Solution 3: Hybrid Approach

Use Terraform template but with a setup script:

**Create `terraform/setup.sh`:**
```bash
#!/bin/bash
# Minimal setup for Terraform template
export OCI_CLI_CONFIG_FILE=${OCI_CLI_CONFIG_FILE:-/oci/config}
echo "Using OCI config: $OCI_CLI_CONFIG_FILE"
```

**Template Configuration:**
- Type: `terraform`
- Playbook: `terraform/`
- Pre-command: `source terraform/setup.sh`

## Why Terraform Template is Better

1. **Automatic TF_VAR handling**: Semaphore automatically exports variables with TF_VAR_ prefix
2. **Built-in Terraform**: No need to install or manage Terraform binary
3. **Working directory management**: Automatically sets correct working directory
4. **State management**: Better handling of Terraform state files
5. **Error handling**: Built-in error handling for Terraform-specific issues

## Quick Fix for Your Current Setup

Since your OCI config is valid and mounted correctly, the simplest fix is:

1. **Change template back to Terraform type**
2. **Keep your TF_VAR_ prefixed variables**
3. **Use minimal or no setup script**

The validation test was failing because it expected shell environment, but you're actually using Terraform template type which handles things differently.

## Testing

To verify which approach works:

```bash
# In Semaphore, create two templates:

# Template 1: Terraform Type
Type: terraform
Playbook: terraform/
Command: plan

# Template 2: Shell Type  
Type: shell
Command: |
  export OCI_CLI_CONFIG_FILE=/oci/config
  cd terraform/
  terraform init
  terraform plan
```

Run both and see which works better with your setup.
