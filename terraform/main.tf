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
provider "oci" {
  # Authentication will be provided via environment variables:
  # TF_VAR_tenancy_ocid
  # TF_VAR_user_ocid
  # TF_VAR_fingerprint
  # TF_VAR_private_key_path
  # TF_VAR_region
  
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
  
  # Also use config file profile if available
  config_file_profile = "DEFAULT"
  # Authentication via TF_VAR_oci_cli_config = /oci/config (mounted from ~/.oci)
}

# Data sources for existing infrastructure
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}