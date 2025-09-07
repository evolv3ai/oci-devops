# FIXED VERSION - Using Config File Authentication
# This file has been restored to use the PROVEN config file authentication method

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
# USING CONFIG FILE AUTHENTICATION (PROVEN TO WORK)
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
    values = ["8"]  # Broad for OL8
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

# Safely handle image selection with fallback
locals {
  # Use first available image or fallback to a specific OCID if needed
  instance_image_id = length(data.oci_core_images.oracle_linux.images) > 0 ? (
    data.oci_core_images.oracle_linux.images[0].id
  ) : (
    var.fallback_image_ocid != "" ? var.fallback_image_ocid : ""
  )
}

# Create VCN if it doesn't exist
resource "oci_core_vcn" "semaphore_vcn" {
  count          = var.create_vcn ? 1 : 0
  compartment_id = var.compartment_id
  cidr_blocks    = ["10.0.0.0/16"]