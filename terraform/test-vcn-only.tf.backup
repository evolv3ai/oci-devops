# Simple Test Configuration - VCN Only
# Purpose: Validate OCI authentication before complex deployments

terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

# Use config file authentication (PROVEN TO WORK)
provider "oci" {
  config_file_profile = "DEFAULT"
}

# Variables for testing
variable "compartment_id" {
  description = "OCID of the compartment"
  type        = string
}

variable "region" {
  description = "OCI region"
  type        = string
  default     = "us-ashburn-1"
}

# Minimal resource - just a VCN to test auth
resource "oci_core_vcn" "test_vcn" {
  compartment_id = var.compartment_id
  cidr_blocks    = ["10.99.0.0/16"]
  display_name   = "semaphore-test-vcn-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  dns_label      = "testvcn"
  
  lifecycle {
    create_before_destroy = true
  }
}

# Output to confirm creation
output "test_vcn_id" {
  value       = oci_core_vcn.test_vcn.id
  description = "OCID of the test VCN"
}

output "test_vcn_name" {
  value       = oci_core_vcn.test_vcn.display_name
  description = "Display name of the test VCN"
}

output "test_status" {
  value       = "SUCCESS - Authentication working!"
  description = "Status message"
}