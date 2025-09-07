# Outputs - Workspace aware

# General Outputs
output "current_workspace" {
  value       = terraform.workspace
  description = "Current Terraform workspace"
}

output "workspace_config" {
  value       = local.current_config
  description = "Configuration for current workspace"
}

# VCN Outputs (when VCN is deployed)
output "vcn_id" {
  value       = local.current_config.deploy_vcn ? oci_core_vcn.main[0].id : "N/A - VCN not deployed in this workspace"
  description = "OCID of the VCN"
}

output "vcn_name" {
  value       = local.current_config.deploy_vcn ? oci_core_vcn.main[0].display_name : "N/A - VCN not deployed in this workspace"
  description = "Display name of the VCN"
}

output "vcn_cidr" {
  value       = local.current_config.deploy_vcn ? oci_core_vcn.main[0].cidr_blocks[0] : "N/A - VCN not deployed in this workspace"
  description = "CIDR block of the VCN"
}

# Compute Outputs (when compute is deployed)
output "instance_public_ip" {
  value       = local.current_config.deploy_compute ? oci_core_instance.semaphore[0].public_ip : "N/A - Compute not deployed in this workspace"
  description = "Public IP of Semaphore instance"
}

output "instance_id" {
  value       = local.current_config.deploy_compute ? oci_core_instance.semaphore[0].id : "N/A - Compute not deployed in this workspace"
  description = "OCID of Semaphore instance"
}

# Status Output
output "deployment_status" {
  value = {
    workspace     = terraform.workspace
    vcn_deployed  = local.current_config.deploy_vcn
    compute_deployed = local.current_config.deploy_compute
    message = terraform.workspace == "test-vcn-only" ? "SUCCESS - Test VCN deployment only (authentication validated)" : "Full infrastructure deployment for ${terraform.workspace}"
  }
  description = "Deployment status for current workspace"
}