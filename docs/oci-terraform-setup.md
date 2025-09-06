# OCI Terraform Integration with Semaphore - Complete Solution

## Overview
This document provides the unified solution for running Terraform with Oracle Cloud Infrastructure (OCI) in Semaphore UI, combining best practices from multiple implementation attempts.

## Quick Start

### 1. Docker Setup
Ensure your `docker-compose.yml` includes OCI configuration mount:
```yaml
volumes:
  - ~/.oci:/home/semaphore/.oci:ro  # Mount at standard location
```

### 2. Semaphore Template Configuration

#### Option A: Using the Setup Script (Recommended)
```bash
#!/bin/bash
set -e

# Initialize OCI environment
chmod +x ./scripts/oci-terraform-setup.sh
source ./scripts/oci-terraform-setup.sh

# Run Terraform
terraform init -input=false
terraform plan -input=false
terraform apply -auto-approve
```

#### Option B: Using the Wrapper Script
```bash
#!/bin/bash
./scripts/terraform-wrapper.sh init -input=false
./scripts/terraform-wrapper.sh plan
./scripts/terraform-wrapper.sh apply -auto-approve
```

#### Option C: Quick Init (Minimal)
```bash
#!/bin/bash
source ./terraform/init-oci.sh
terraform init && terraform apply -auto-approve
```

## File Structure
```
semaphore-ui/
├── docker-compose.yml          # Container configuration with OCI mount
├── scripts/
│   ├── oci-terraform-setup.sh  # Universal OCI setup script
│   └── terraform-wrapper.sh    # Terraform wrapper with auto-setup
├── terraform/
│   ├── init-oci.sh            # Quick initialization script
│   ├── main.tf                 # Terraform configuration
│   ├── variables.tf            # Variable definitions
│   └── terraform.tfvars.example # Example variables file
└── docs/
    └── oci-terraform-setup.md  # This documentation
```

## How It Works

### 1. Environment Detection
The setup script automatically detects whether it's running in:
- Semaphore container environment
- Local development environment
- Docker container

### 2. Configuration Discovery
Searches for OCI config in priority order:
1. `/home/semaphore/.oci/config` (Semaphore standard)
2. `/oci/config` (Docker volume mount)
3. `~/.oci/config` (Local environment)

### 3. Path Correction
Automatically fixes path incompatibilities:
- Windows paths (`C:\Users\...`)
- Unix home paths (`~/...`)
- Path separators (`\` to `/`)

### 4. Profile Management
- Uses specified profile or defaults to `DEFAULT`
- Auto-creates missing profiles from `DEFAULT`
- Validates all required fields

### 5. Key Validation
Searches for private keys in common locations:
- `/home/semaphore/.oci/oci_api_key.pem`
- `/oci/oci_api_key.pem`
- Various other standard locations
- Automatically updates config with correct path
- Sets proper permissions (600)

### 6. Environment Variables
Sets required environment variables:
- `OCI_CLI_CONFIG_FILE` - Config file location
- `TF_VAR_config_file_profile` - Profile for Terraform
- `TF_VAR_compartment_id` - If provided
- `TF_VAR_region` - If provided

## Semaphore Configuration

### Template Settings
- **Type**: `terraform`
- **Playbook**: `terraform/`
- **Working Directory**: (leave empty or set to project root)

### Environment Variables (Variable Group)
Create a Variable Group with these variables (WITH `TF_VAR_` prefix):
```
TF_VAR_tenancy_ocid=ocid1.tenancy.oc1...
TF_VAR_user_ocid=ocid1.user.oc1...
TF_VAR_fingerprint=2b:d5:03:cf:b2...
TF_VAR_region=us-ashburn-1
TF_VAR_compartment_id=ocid1.compartment.oc1...
TF_VAR_ssh_public_key=ssh-rsa AAAAB3...
```

### Key Store (for Private Key)
If not using Docker volume mount:
1. Create SSH key in Key Store
2. Name it appropriately (e.g., `oci-api-key`)
3. Paste your OCI API private key content

## Troubleshooting

### Common Issues and Solutions

#### 1. "OCI config not found"
**Problem**: Config file not accessible in container
**Solution**: 
- Check Docker volume mount in `docker-compose.yml`
- Verify `~/.oci/config` exists on host
- Restart container after adding mount

#### 2. "Private key not found"
**Problem**: Key file path incorrect or inaccessible
**Solution**:
- Script automatically searches common locations
- Ensure key is in `~/.oci/` folder on host
- Check file permissions (should be 600)

#### 3. "Profile not found"
**Problem**: Specified profile doesn't exist in config
**Solution**:
- Script auto-creates from DEFAULT if missing
- Verify DEFAULT profile has all required fields
- Check profile name spelling

#### 4. "Missing required fields"
**Problem**: OCI config incomplete
**Solution**:
- Ensure config has: user, fingerprint, key_file, tenancy, region
- Script attempts to inherit from DEFAULT profile
- Manually add missing fields if needed

#### 5. Environment Variables Not Working
**Problem**: TF_VAR_ variables not being recognized
**Solution**:
- Always use `TF_VAR_` prefix in Semaphore
- Don't use prefix in terraform.tfvars files
- Restart Semaphore container if variables were just added

## Security Best Practices

1. **Never commit sensitive data**:
   - Don't push terraform.tfvars to Git
   - Use .gitignore for OCI credentials
   - Keep private keys secure

2. **Use read-only mounts**:
   ```yaml
   - ~/.oci:/home/semaphore/.oci:ro  # :ro = read-only
   ```

3. **Rotate credentials regularly**:
   - Update OCI API keys periodically
   - Use Semaphore's Key Store for rotation

4. **Limit permissions**:
   - Create OCI policies with minimal required permissions
   - Use compartment-specific access

## Testing

### Local Testing
```bash
# Test the setup script locally
./scripts/oci-terraform-setup.sh

# Test with specific profile
OCI_CONFIG_PROFILE=learn-terraform ./scripts/oci-terraform-setup.sh
```

### Container Testing
```bash
# Enter container
docker exec -it semaphore-ui-semaphore-1 /bin/sh

# Test setup inside container
cd /home/semaphore
./scripts/oci-terraform-setup.sh
```

## Additional Scripts

### Check OCI Configuration
```bash
#!/bin/bash
# check-oci-config.sh
source ./scripts/oci-terraform-setup.sh
oci iam user get --user-id "$TF_VAR_user_ocid"
```

### Validate Terraform
```bash
#!/bin/bash
# validate-terraform.sh
source ./scripts/oci-terraform-setup.sh
terraform init -backend=false
terraform validate
```

## Version History

- **v1.0.0** (2024-01): Unified solution combining best practices
  - Comprehensive path fixing
  - Automatic profile management
  - Key discovery and validation
  - Environment variable setup

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the setup script output for specific errors
3. Verify Docker and Semaphore configurations
4. Check OCI credentials and permissions

## License

This solution is provided as-is for use with Semaphore UI and Oracle Cloud Infrastructure.
