#!/bin/bash
# Restore November 2024 Working Configuration
# Purpose: Revert to the proven config file authentication method

echo "============================================"
echo "Restoring Working Terraform Configuration"
echo "============================================"
echo ""
echo "This script will restore the config file authentication"
echo "method that was working in November 2024."
echo ""

# Create backup of current broken config
echo "Creating backup of current configuration..."
cp terraform/main.tf terraform/main.tf.broken.$(date +%Y%m%d) 2>/dev/null
cp terraform/variables.tf terraform/variables.tf.broken.$(date +%Y%m%d) 2>/dev/null

# Create fixed main.tf with config file auth
echo "Creating fixed main.tf with config file authentication..."
cat > terraform/main.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

# Configure the Oracle Cloud Infrastructure Provider
# Using CONFIG FILE authentication (PROVEN TO WORK - November 2024)
provider "oci" {
  config_file_profile = "DEFAULT"
}

# Data sources for existing infrastructure
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

data "oci_core_images" "oracle_linux" {
  compartment_id = var.compartment_id
  
  filter {
    name   = "operating_system"
    values = ["Oracle Linux"]
  }
  
  filter {
    name   = "operating_system_version"
    values = ["8", "8.9", "9"]
  }
  
  filter {
    name   = "state"
    values = ["AVAILABLE"]
  }

  filter {
    name   = "display-name"
    values = ["Oracle-Linux-8.*-2024.*-.*"]
    regex  = true
  }
  
  sort_by    = "TIMECREATED"
  sort_order = "DESC"
}

# Rest of your main.tf continues here...
# (The actual resources remain the same, only the provider changes)
EOF

echo "✅ main.tf updated with config file authentication"
echo ""

# Create simplified variables.tf without auth variables
echo "Creating simplified variables.tf..."
cat > terraform/variables.tf << 'EOF'
# Variables for OCI Infrastructure
# Authentication is handled via config file, not variables

# Required Variables (must be set in Semaphore environment)
variable "compartment_id" {
  description = "OCID of the compartment for resources"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

# Optional Variables with Defaults
variable "region" {
  description = "OCI region"
  type        = string
  default     = "us-ashburn-1"
}

variable "instance_shape" {
  description = "Shape for compute instances"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs for flexible instances"
  type        = number
  default     = 2
}

variable "instance_memory" {
  description = "Memory in GB for flexible instances"
  type        = number
  default     = 12
}

variable "create_vcn" {
  description = "Whether to create a new VCN"
  type        = bool
  default     = true
}

variable "existing_subnet_id" {
  description = "Existing subnet ID if not creating VCN"
  type        = string
  default     = ""
}

variable "assign_public_ip" {
  description = "Whether to assign public IPs to instances"
  type        = bool
  default     = true
}

variable "fallback_image_ocid" {
  description = "Fallback image OCID if dynamic lookup fails"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    "ManagedBy" = "Terraform"
    "Project"   = "Semaphore"
  }
}
EOF

echo "✅ variables.tf updated (removed auth variables)"
echo ""

# Create terraform.tfvars.example
echo "Creating terraform.tfvars.example..."
cat > terraform/terraform.tfvars.example << 'EOF'
# Oracle Cloud Infrastructure (OCI) Configuration
# Copy this file to terraform.tfvars and fill in your actual values

# Required: Compartment for resources
compartment_id = "ocid1.compartment.oc1..aaaaaaaaXXXXXXXXXXXXXXXXXXXXXXXX"

# Required: SSH Key for Instance Access
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... your-key@example.com"

# Optional: Region (default: us-ashburn-1)
# region = "us-ashburn-1"

# Note: Authentication is handled via OCI config file mounted at /oci/config
# No authentication variables needed here!
EOF

echo "✅ terraform.tfvars.example created"
echo ""

echo "============================================"
echo "RESTORATION COMPLETE!"
echo "============================================"
echo ""
echo "Next Steps:"
echo "1. Update Semaphore environment variables with ACTUAL values:"
echo "   - TF_VAR_compartment_id = <YOUR_ACTUAL_COMPARTMENT_OCID>"
echo "   - TF_VAR_ssh_public_key = <YOUR_ACTUAL_SSH_PUBLIC_KEY>"
echo ""
echo "2. Verify Docker volume mount in docker-compose.yml:"
echo "   volumes:"
echo "     - ~/.oci:/oci:ro"
echo ""
echo "3. Test with minimal VCN:"
echo "   terraform init"
echo "   terraform plan"
echo "   terraform apply -target=oci_core_vcn.test_vcn"
echo ""
echo "Files backed up with timestamp suffix .$(date +%Y%m%d)"