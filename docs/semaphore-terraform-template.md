# Semaphore Terraform Template Guide

## Overview
This guide provides instructions for creating and configuring Terraform templates in Semaphore UI for Oracle Cloud Infrastructure (OCI) deployments.

## Template Configuration

### 1. Create a New Template

1. Navigate to your Semaphore project
2. Go to **Task Templates**
3. Click **New Template**
4. Configure as follows:

```yaml
Name: OCI Terraform Deploy
Description: Deploy infrastructure to Oracle Cloud using Terraform
Type: terraform
Repository: Your Git repository with Terraform files
Branch: main
Playbook: terraform/  # Directory containing .tf files
```

### 2. Environment Variables

Add the following variable in the template's **Environment** section:

```bash
TF_VAR_oci_cli_config = /oci/config
```

This single variable enables OCI authentication through the mounted config file.

### 3. Docker Configuration

Ensure your `docker-compose.yml` includes the OCI config mount:

```yaml
services:
  semaphore:
    volumes:
      - ~/.oci:/oci:ro  # Mount OCI config directory as read-only
```

## Working Configuration

### Simple Authentication Method (Proven Working)
This method uses the OCI CLI configuration file mounted into the container:

1. **Local Setup**: Ensure `~/.oci/config` exists with proper credentials
2. **Docker Mount**: Volume maps `~/.oci` to `/oci` in container
3. **Terraform Variable**: `TF_VAR_oci_cli_config` points to `/oci/config`
4. **Provider Config**: Terraform provider uses config file authentication

### Provider Configuration
```hcl
provider "oci" {
  config_file_profile = "DEFAULT"
  # Config file path is automatically set via TF_VAR_oci_cli_config
}
```

## Common OCI Resources

### 1. Virtual Cloud Network (VCN)
```hcl
resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_id
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "semaphore-vcn"
  dns_label      = "semaphore"
}
```

### 2. Compute Instance
```hcl
resource "oci_core_instance" "main" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  shape              = "VM.Standard.E2.1.Micro"  # Free tier
  
  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oracle_linux.images[0].id
  }
  
  display_name = "semaphore-worker"
}
```

### 3. Image Data Source (Fixed)
```hcl
data "oci_core_images" "oracle_linux" {
  compartment_id = var.compartment_id
  
  filter {
    name   = "operating_system"
    values = ["Oracle Linux"]
  }
  
  filter {
    name   = "operating_system_version"
    values = ["8.9", "9.3"]  # Current stable versions
  }
  
  filter {
    name   = "shape"
    values = ["VM.Standard.E2.1.Micro"]  # Must match instance shape
  }
  
  filter {
    name   = "state"
    values = ["AVAILABLE"]
  }
  
  sort_by    = "TIMECREATED"
  sort_order = "DESC"
}
```

## Troubleshooting

### Image Selection Issue
**Problem**: "Invalid index - The given key does not identify an element in this collection value"

**Solution**: The image data source filters must match available images:
1. Verify shape compatibility
2. Check operating system version availability
3. Use fallback image OCID if dynamic lookup fails

```hcl
locals {
  # Fallback to specific image if lookup fails
  instance_image_id = length(data.oci_core_images.oracle_linux.images) > 0 ? 
    data.oci_core_images.oracle_linux.images[0].id : 
    "ocid1.image.oc1.iad.aaaaaaaaXXXXXXXX"  # Replace with valid image OCID
}
```

### Authentication Issues
**Problem**: Provider cannot authenticate with OCI

**Solutions**:
1. Verify OCI config file exists: `~/.oci/config`
2. Check Docker volume mount in `docker-compose.yml`
3. Ensure `TF_VAR_oci_cli_config` environment variable is set
4. Validate OCI credentials with CLI: `oci iam user get --user-id <your-user-ocid>`

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "404-NotAuthorizedOrNotFound" | Wrong compartment or missing permissions | Verify compartment OCID and IAM policies |
| "Invalid private key" | Key format or permissions issue | Check PEM file format and permissions (600) |
| "Service limit exceeded" | Resource quota reached | Check OCI limits and quotas in console |

## Context7 Integration

### Using Context7 for OCI Terraform Documentation

Use Context7 MCP tool to access comprehensive OCI Terraform provider documentation:

**Library ID**: `oracle/terraform-provider-oci`

**Example Queries**:
- "oci_core_instance resource attributes"
- "oci_core_vcn examples"
- "image data source filters"
- "authentication configuration"
- "shape compatibility"

**How to Use**:
1. Query Context7 for specific resource documentation
2. Get up-to-date syntax and examples
3. Find best practices and common patterns
4. Troubleshoot specific error messages

### Sample Context7 Workflow

```markdown
# When creating a new resource:
1. Query: "oci_core_load_balancer resource"
2. Review required and optional arguments
3. Check example configurations
4. Understand dependencies and relationships
```

## Best Practices

### 1. State Management
- Store Terraform state in OCI Object Storage for team collaboration
- Use state locking with OCI Database

### 2. Variable Organization
- Use Semaphore Variable Groups for sensitive data
- Never commit `terraform.tfvars` with real values
- Use consistent naming: `TF_VAR_` prefix for all Terraform variables

### 3. Template Structure
```
terraform/
├── main.tf          # Main resource definitions
├── variables.tf     # Variable declarations
├── outputs.tf       # Output values for other templates
├── versions.tf      # Provider version constraints
└── terraform.tfvars.example  # Example configuration
```

### 4. Resource Tagging
```hcl
locals {
  common_tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Project     = "Semaphore"
    CreatedDate = timestamp()
  }
}

resource "oci_core_instance" "main" {
  # ... other configuration ...
  
  freeform_tags = local.common_tags
}
```

## Integration with Ansible

### Terraform Outputs for Ansible
Define outputs that Ansible can use:

```hcl
output "instance_public_ip" {
  value = oci_core_instance.main.public_ip
}

output "instance_private_key_path" {
  value = var.ssh_private_key_path
}

output "instance_user" {
  value = "opc"  # Default for Oracle Linux
}
```

### Using Outputs in Next Template
Create a subsequent Ansible template that uses these outputs as inventory.

## Execution Flow

### 1. Plan Stage
```bash
terraform plan -out=tfplan
```

### 2. Apply Stage
```bash
terraform apply tfplan
```

### 3. Destroy (When Needed)
```bash
terraform destroy -auto-approve
```

## Security Considerations

1. **Never expose sensitive values in logs**
   - Use `sensitive = true` for variables
   - Mask outputs containing secrets

2. **Principle of Least Privilege**
   - Create specific IAM policies for Terraform
   - Limit compartment access

3. **Audit and Compliance**
   - Enable OCI Audit logging
   - Tag resources for tracking

## Additional Resources

- [OCI Terraform Provider Documentation](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [Semaphore CI Documentation](https://docs.semaphoreui.com/)
- [OCI Free Tier Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier.htm)

---

*Last Updated: November 2024*
*Template Version: 1.0*
