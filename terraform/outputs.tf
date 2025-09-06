# Terraform Outputs - These will be captured by Semaphore

# Instance Information
output "instance_ids" {
  description = "OCIDs of the created instances"
  value       = oci_core_instance.semaphore_instance[*].id
}

output "instance_public_ips" {
  description = "Public IP addresses of the instances"
  value       = oci_core_instance.semaphore_instance[*].public_ip
}

output "instance_private_ips" {
  description = "Private IP addresses of the instances"
  value       = oci_core_instance.semaphore_instance[*].private_ip
}

output "instance_display_names" {
  description = "Display names of the instances"
  value       = oci_core_instance.semaphore_instance[*].display_name
}

# Primary instance outputs (for single instance deployments)
output "primary_instance_id" {
  description = "OCID of the primary instance"
  value       = length(oci_core_instance.semaphore_instance) > 0 ? oci_core_instance.semaphore_instance[0].id : null
}

output "primary_public_ip" {
  description = "Public IP of the primary instance"
  value       = length(oci_core_instance.semaphore_instance) > 0 ? oci_core_instance.semaphore_instance[0].public_ip : null
}

output "primary_private_ip" {
  description = "Private IP of the primary instance"
  value       = length(oci_core_instance.semaphore_instance) > 0 ? oci_core_instance.semaphore_instance[0].private_ip : null
}

# Network Information
output "vcn_id" {
  description = "OCID of the VCN"
  value       = var.create_vcn ? oci_core_vcn.semaphore_vcn[0].id : null
}

output "subnet_id" {
  description = "OCID of the subnet"
  value       = var.create_vcn ? oci_core_subnet.semaphore_subnet[0].id : var.existing_subnet_id
}

# Ansible Inventory Variables (JSON format for Semaphore)
output "ansible_inventory_vars" {
  description = "Variables for Ansible inventory in JSON format"
  value = jsonencode({
    oci_instance_ips    = oci_core_instance.semaphore_instance[*].public_ip
    oci_private_ips     = oci_core_instance.semaphore_instance[*].private_ip
    oci_instance_ids    = oci_core_instance.semaphore_instance[*].id
    oci_display_names   = oci_core_instance.semaphore_instance[*].display_name
    primary_public_ip   = length(oci_core_instance.semaphore_instance) > 0 ? oci_core_instance.semaphore_instance[0].public_ip : ""
    primary_private_ip  = length(oci_core_instance.semaphore_instance) > 0 ? oci_core_instance.semaphore_instance[0].private_ip : ""
    instance_count      = var.instance_count
    environment         = var.environment
    region              = var.region
  })
}

# SSH Connection Commands
output "ssh_commands" {
  description = "SSH commands to connect to instances"
  value = [
    for i, instance in oci_core_instance.semaphore_instance :
    "ssh -i ~/.ssh/semaphore-oci-key opc@${instance.public_ip}"
  ]
}

# Semaphore Environment Variables (for updating Semaphore)
output "semaphore_env_vars" {
  description = "Environment variables to update in Semaphore"
  value = {
    TF_VAR_primary_public_ip  = length(oci_core_instance.semaphore_instance) > 0 ? oci_core_instance.semaphore_instance[0].public_ip : ""
    TF_VAR_primary_private_ip = length(oci_core_instance.semaphore_instance) > 0 ? oci_core_instance.semaphore_instance[0].private_ip : ""
    TF_VAR_instance_count     = var.instance_count
    TF_VAR_region             = var.region
    TF_VAR_environment        = var.environment
  }
}

# Instance State
output "instance_state" {
  description = "State of the instances"
  value       = oci_core_instance.semaphore_instance[*].state
}

# Availability Domain
output "availability_domain" {
  description = "Availability domain of the instances"
  value       = length(oci_core_instance.semaphore_instance) > 0 ? oci_core_instance.semaphore_instance[0].availability_domain : null
}
