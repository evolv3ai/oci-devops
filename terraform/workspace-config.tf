# Workspace-based VCN Configuration
# This file handles VCN creation for different workspaces

locals {
  # Workspace-specific configuration
  workspace_config = {
    "test-vcn-only" = {
      deploy_vcn     = true
      deploy_compute = false
      vcn_cidr      = "10.99.0.0/16"
      vcn_name      = "test-vcn"
    }
    "production" = {
      deploy_vcn     = true
      deploy_compute = true
      vcn_cidr      = "10.0.0.0/16"
      vcn_name      = "prod-vcn"
    }
    "dev" = {
      deploy_vcn     = true
      deploy_compute = true
      vcn_cidr      = "10.1.0.0/16"
      vcn_name      = "dev-vcn"
    }
    "default" = {
      deploy_vcn     = false
      deploy_compute = false
      vcn_cidr      = "10.2.0.0/16"
      vcn_name      = "default-vcn"
    }
  }

  # Get current workspace config with fallback to default
  current_config = lookup(local.workspace_config, terraform.workspace, local.workspace_config["default"])
}