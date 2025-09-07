# Terraform Outputs - These will be captured by Semaphore

# Instance Information
output "kasm_instance_id" {
  description = "OCID of the KASM instance"
  value       = oci_core_instance.kasm.id
}

output "coolify_instance_id" {
  description = "OCID of the Coolify instance"
  value       = oci_core_instance.coolify.id
}

output "instance_public_ips" {
  description = "Public IP addresses of the instances"
  value       = [oci_core_instance.kasm.public_ip, oci_core_instance.coolify.public_ip]
}

output "instance_private_ips" {
  description = "Private IP addresses of the instances"
  value       = [oci_core_instance.kasm.private_ip, oci_core_instance.coolify.private_ip]
}

output "instance_display_names" {
  description = "Display names of the instances"
  value       = ["kasm-server", "coolify-server"]
}

output "kasm_public_ip" {
  description = "Public IP of the KASM instance"
  value       = oci_core_instance.kasm.public_ip
}

output "coolify_public_ip" {
  description = "Public IP of the Coolify instance"
  value       = oci_core_instance.coolify.public_ip
}

output "kasm_private_ip" {
  description = "Private IP of the KASM instance"
  value       = oci_core_instance.kasm.private_ip
}

output "coolify_private_ip" {
  description = "Private IP of the Coolify instance"
  value       = oci_core_instance.coolify.private_ip
}

# Primary instance outputs (KASM as primary)
output "primary_instance_id" {
  description = "OCID of the primary (KASM) instance"
  value       = oci_core_instance.kasm.id
}

output "primary_public_ip" {
  description = "Public IP of the primary (KASM) instance"
  value       = oci_core_instance.kasm.public_ip
}

output "primary_private_ip" {
  description = "Private IP of the primary (KASM) instance"
  value       = oci_core_instance.kasm.private_ip
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
    oci_instance_ips    = [oci_core_instance.kasm.public_ip, oci_core_instance.coolify.public_ip]
    oci_private_ips     = [oci_core_instance.kasm.private_ip, oci_core_instance.coolify.private_ip]
    oci_instance_ids    = [oci_core_instance.kasm.id, oci_core_instance.coolify.id]
    oci_display_names   = ["kasm-server", "coolify-server"]
    primary_public_ip   = oci_core_instance.kasm.public_ip
    primary_private_ip  = oci_core_instance.kasm.private_ip
    kasm_public_ip      = oci_core_instance.kasm.public_ip
    kasm_private_ip     = oci_core_instance.kasm.private_ip
    coolify_public_ip   = oci_core_instance.coolify.public_ip
    coolify_private_ip  = oci_core_instance.coolify.private_ip
    instance_count      = 2
    environment         = var.environment
    region              = var.region
  })
}

# SSH Connection Commands
output "ssh_commands" {
  description = "SSH commands to connect to instances"
  value = [
    "ssh -i ~/.ssh/semaphore-oci-key opc@${oci_core_instance.kasm.public_ip}",
    "ssh -i ~/.ssh/semaphore-oci-key opc@${oci_core_instance.coolify.public_ip}"
  ]
}

# Semaphore Environment Variables (for updating Semaphore)
output "semaphore_env_vars" {
  description = "Environment variables to update in Semaphore"
  value = {
    TF_VAR_kasm_public_ip     = oci_core_instance.kasm.public_ip
    TF_VAR_kasm_private_ip    = oci_core_instance.kasm.private_ip
    TF_VAR_coolify_public_ip  = oci_core_instance.coolify.public_ip
    TF_VAR_coolify_private_ip = oci_core_instance.coolify.private_ip
    TF_VAR_primary_public_ip  = oci_core_instance.kasm.public_ip
    TF_VAR_primary_private_ip = oci_core_instance.kasm.private_ip
    TF_VAR_instance_count     = 2
    TF_VAR_region             = var.region
    TF_VAR_environment        = var.environment
  }
}

# Instance State
output "instance_state" {
  description = "State of the instances"
  value       = [oci_core_instance.kasm.state, oci_core_instance.coolify.state]
}

# Availability Domain
output "availability_domain" {
  description = "Availability domain of the instances"
  value       = data.oci_identity_availability_domains.ads.availability_domains[0].name
}

# Volume Information
output "kasm_volume_id" {
  description = "OCID of the KASM block volume"
  value       = oci_core_volume.kasm_volume.id
}

output "coolify_volume_id" {
  description = "OCID of the Coolify block volume"
  value       = oci_core_volume.coolify_volume.id
}
