# Compute Resources - Only deployed for production and dev workspaces

# Get the latest Oracle Linux image
data "oci_core_images" "oracle_linux" {
  count = local.current_config.deploy_compute ? 1 : 0

  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Compute Instance for Semaphore
resource "oci_core_instance" "semaphore" {
  count = local.current_config.deploy_compute ? 1 : 0

  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "${terraform.workspace}-semaphore-instance"
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public[0].id
    display_name     = "${terraform.workspace}-primary-vnic"
    assign_public_ip = var.assign_public_ip
    hostname_label   = "${terraform.workspace}-semaphore"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oracle_linux[0].images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/user-data.sh", {
      workspace = terraform.workspace
    }))
  }

  freeform_tags = merge(
    var.common_tags,
    {
      "Workspace"   = terraform.workspace
      "Environment" = terraform.workspace
      "Application" = "Semaphore"
    }
  )
}

# Security List for Semaphore (only for compute deployments)
resource "oci_core_security_list" "semaphore" {
  count = local.current_config.deploy_compute ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main[0].id
  display_name   = "${terraform.workspace}-semaphore-security-list"

  # Egress - Allow all outbound
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  # Ingress - SSH
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Ingress - Semaphore UI (Port 3000)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      min = 3000
      max = 3000
    }
  }

  # Ingress - HTTPS (if needed)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      min = 443
      max = 443
    }
  }

  freeform_tags = merge(
    var.common_tags,
    {
      "Workspace" = terraform.workspace
    }
  )
}