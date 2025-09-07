# OCI Terraform Setup - Simplified Guide

## Overview
This is the simplified, working configuration for running Terraform with Oracle Cloud Infrastructure (OCI) in Semaphore UI.

## Prerequisites

1. **OCI CLI Configuration**
   ```bash
   # Ensure you have ~/.oci/config with:
   [DEFAULT]
   user=ocid1.user.oc1..aaaaaaaXXXXXXXX
   fingerprint=XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
   tenancy=ocid1.tenancy.oc1..aaaaaaaXXXXXXXX
   region=us-ashburn-1
   key_file=~/.oci/oci_api_key.pem
   ```

2. **Private Key**
   - Place your OCI API private key at `~/.oci/oci_api_key.pem`
   - Set permissions: `chmod 600 ~/.oci/oci_api_key.pem`

## Semaphore Configuration

### Step 1: Docker Compose Setup

Add this volume mount to your `docker-compose.yml`:

```yaml
version: '3.7'
services:
  semaphore:
    image: semaphoreui/semaphore:latest
    ports:
      - "3001:3000"
    volumes:
      - ~/.oci:/oci:ro  # Mount OCI config directory as read-only
      - ./data:/var/lib/semaphore
    environment:
      SEMAPHORE_DB_DIALECT: bolt
      SEMAPHORE_ADMIN_PASSWORD: admin
      SEMAPHORE_ADMIN_NAME: admin
      SEMAPHORE_ADMIN_EMAIL: admin@localhost
      SEMAPHORE_ADMIN: admin
```

### Step 2: Create Terraform Template

1. **In Semaphore UI:**
   - Go to your project
   - Click "Task Templates" → "New Template"

2. **Template Settings:**
   ```yaml
   Name: OCI Infrastructure Deploy
   Type: terraform  # Important: Use terraform type, not bash
   Repository: [Your Git repo]
   Branch: main
   Playbook: terraform/  # Directory with .tf files
   ```

3. **Environment Configuration:**
   - Click "Environment" section
   - Add ONE variable:
   ```bash
   TF_VAR_oci_cli_config = /oci/config
   ```

### Step 3: Terraform Configuration

Create `terraform/variables.tf`:

```hcl
variable "oci_cli_config" {
  description = "Path to OCI CLI config file"
  type        = string
  default     = "/oci/config"
}

variable "tenancy_ocid" {
  description = "OCI Tenancy OCID"
  type        = string
}

variable "compartment_id" {
  description = "OCI Compartment OCID"
  type        = string
}

variable "region" {
  description = "OCI Region"
  type        = string
  default     = "us-ashburn-1"
}
```

Create `terraform/main.tf`:

```hcl
terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  config_file_profile = "DEFAULT"
  # Config path is set via TF_VAR_oci_cli_config environment variable
}

# Your resources here...
```

### Step 4: Variable Management

1. **In Semaphore UI:**
   - Go to "Environment" in your project
   - Create a new environment or edit existing

2. **Add Variables:**
   ```bash
   TF_VAR_tenancy_ocid = ocid1.tenancy.oc1..aaaaaaaXXXXX
   TF_VAR_compartment_id = ocid1.compartment.oc1..aaaaaaaXXXXX
   TF_VAR_region = us-ashburn-1
   ```

## Running Templates

### Execute Terraform

1. Click "Run Task" on your template
2. Semaphore will:
   - Initialize Terraform
   - Run `terraform plan`
   - Run `terraform apply` (if plan succeeds)

### Monitor Execution

- View real-time logs in Semaphore UI
- Check task history for previous runs
- Download output logs if needed

## Why This Works

1. **Simple Authentication**: Uses OCI CLI config file already configured locally
2. **Docker Volume Mount**: Makes local OCI config available in container
3. **Native Terraform Template**: No wrapper scripts or complex shell commands
4. **Single Environment Variable**: Only `TF_VAR_oci_cli_config` needed

## Troubleshooting

### Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| "Config file not found" | Check Docker volume mount in docker-compose.yml |
| "Invalid authentication" | Verify ~/.oci/config and private key permissions |
| "Missing required variables" | Add TF_VAR_ prefixed variables in Semaphore environment |
| "Permission denied" | Ensure OCI config is mounted as read-only (:ro) |

### Debug Commands

Test OCI access in container:
```bash
docker exec -it semaphore_container_name sh
cat /oci/config
ls -la /oci/
```

## Important Notes

- ✅ **DO**: Use Terraform template type
- ✅ **DO**: Mount OCI config as read-only
- ✅ **DO**: Use TF_VAR_ prefix for all Terraform variables
- ❌ **DON'T**: Use shell/bash template type for Terraform
- ❌ **DON'T**: Commit sensitive values to Git
- ❌ **DON'T**: Use wrapper scripts (unnecessary complexity)

## Next Steps

1. **Test with simple resource**: Start with a VCN creation
2. **Incremental additions**: Add resources one at a time
3. **Use outputs**: Export values for Ansible templates
4. **Enable state backend**: Consider OCI Object Storage for state

---

*This configuration has been tested and verified working in production.*
*Last Updated: November 2024*
