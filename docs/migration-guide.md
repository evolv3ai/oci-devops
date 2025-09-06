# Migration Guide: From Old Scripts to Unified Solution

## Overview
This guide helps you migrate from the various OCI authentication scripts to the new unified solution.

## Script Mapping

### If you were using `infra/terraform/init-oci-env.sh`:
Replace with: `scripts/oci-terraform-setup.sh`

**Old usage:**
```bash
source ./init-oci-env.sh
terraform init
```

**New usage:**
```bash
source ./scripts/oci-terraform-setup.sh
terraform init
```

### If you were using `learn-terraform-oci/oci-terraform-universal.sh`:
Replace with: `scripts/oci-terraform-setup.sh`

**Old usage:**
```bash
./oci-terraform-universal.sh
```

**New usage:**
```bash
source ./scripts/oci-terraform-setup.sh
terraform plan -input=false
```

### If you were using manual environment variables:
Use the new setup script which handles this automatically.

**Old approach:**
```bash
export OCI_CLI_CONFIG_FILE="/home/semaphore/.oci/config"
export TF_VAR_private_key_path="/oci/oci_api_key.pem"
```

**New approach:**
```bash
source ./scripts/oci-terraform-setup.sh
# All variables are set automatically
```

## Semaphore Template Updates

### Old Template Configuration
```yaml
commands:
  - chmod +x ./init-oci-env.sh
  - source ./init-oci-env.sh
  - terraform init
  - terraform apply
```

### New Template Configuration
```yaml
commands:
  - chmod +x ./scripts/oci-terraform-setup.sh
  - source ./scripts/oci-terraform-setup.sh
  - terraform init -input=false
  - terraform plan -input=false
  - terraform apply -auto-approve
```

## Key Improvements

1. **Unified Path Handling**: Automatically fixes Windows, Unix, and mixed paths
2. **Profile Management**: Auto-creates missing profiles from DEFAULT
3. **Key Discovery**: Searches multiple locations for private keys
4. **Better Error Messages**: Clear, actionable error messages
5. **Environment Detection**: Works in containers and local environments

## Cleanup

After migrating, you can remove old scripts:
```bash
# Remove old scripts (after confirming new setup works)
rm infra/terraform/init-oci-env.sh
rm infra/terraform/terraform-wrapper.sh
rm learn-terraform-oci/init-oci-env.sh
rm learn-terraform-oci/oci-terraform-universal.sh
```

## Testing Migration

1. **Test the new setup script:**
   ```bash
   ./scripts/oci-terraform-setup.sh
   ```

2. **Verify environment variables:**
   ```bash
   echo $OCI_CLI_CONFIG_FILE
   echo $TF_VAR_config_file_profile
   ```

3. **Run Terraform init:**
   ```bash
   terraform init -input=false
   ```

4. **If successful, update Semaphore templates**

## Rollback Plan

If issues occur, the old scripts are preserved in their original locations until you explicitly remove them. You can revert by:

1. Using the old script paths in Semaphore templates
2. Keeping both old and new scripts during transition
3. Testing thoroughly before removing old scripts

## Support

For migration issues:
1. Compare old script output with new script output
2. Check that all environment variables are set correctly
3. Verify OCI configuration is accessible
4. Review the main documentation at `docs/oci-terraform-setup.md`
