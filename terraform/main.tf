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
  config_file_profile = "DEFAULT"
  # Authentication via TF_VAR_oci_cli_config = /oci/config (mounted from ~/.oci)
  region = var.region
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
  display_name   = "semaphore-vcn"
  dns_label      = "semaphorevcn"

  freeform_tags = var.common_tags
}

# Create Internet Gateway
resource "oci_core_internet_gateway" "semaphore_igw" {
  count          = var.create_vcn ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.semaphore_vcn[0].id
  display_name   = "semaphore-igw"
  enabled        = true

  freeform_tags = var.common_tags
}

# Create Route Table
resource "oci_core_route_table" "semaphore_rt" {
  count          = var.create_vcn ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.semaphore_vcn[0].id
  display_name   = "semaphore-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.semaphore_igw[0].id
  }

  freeform_tags = var.common_tags
}

# Create Security List
resource "oci_core_security_list" "semaphore_sl" {
  count          = var.create_vcn ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.semaphore_vcn[0].id
  display_name   = "semaphore-security-list"

  # Allow SSH
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    
    tcp_options {
      min = 22
      max = 22
    }
  }

  # Allow HTTP
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    
    tcp_options {
      min = 80
      max = 80
    }
  }

  # Allow HTTPS
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    
    tcp_options {
      min = 443
      max = 443
    }
  }

  # Allow Coolify UI (port 3000)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    
    tcp_options {
      min = 3000
      max = 3000
    }
  }

  # Allow all outbound traffic
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  freeform_tags = var.common_tags
}

# Create Subnet
resource "oci_core_subnet" "semaphore_subnet" {
  count               = var.create_vcn ? 1 : 0
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_vcn.semaphore_vcn[0].id
  cidr_block          = "10.0.1.0/24"
  display_name        = "semaphore-subnet"
  dns_label           = "semaphoresubnet"
  route_table_id      = oci_core_route_table.semaphore_rt[0].id
  security_list_ids   = [oci_core_security_list.semaphore_sl[0].id]
  
  freeform_tags = var.common_tags
}

# Create KASM Compute Instance
resource "oci_core_instance" "kasm" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  display_name        = "kasm-server"
  shape               = var.instance_shape

  # Shape configuration for flexible shapes
  shape_config {
    memory_in_gbs = var.instance_memory
    ocpus         = var.instance_ocpus
  }

  create_vnic_details {
    subnet_id        = var.create_vcn ? oci_core_subnet.semaphore_subnet[0].id : var.existing_subnet_id
    display_name     = "kasm-vnic"
    assign_public_ip = var.assign_public_ip
    assign_private_dns_record = true
  }

  source_details {
    source_type = "image"
    source_id   = local.instance_image_id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/cloud-init.yml", {
      ssh_public_key = var.ssh_public_key
    }))
  }

  freeform_tags = merge(var.common_tags, {
    "Instance" = "kasm-server"
  })

  timeouts {
    create = "60m"
  }
}

# Create Coolify Compute Instance
resource "oci_core_instance" "coolify" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  display_name        = "coolify-server"
  shape               = var.instance_shape

  # Shape configuration for flexible shapes
  shape_config {
    memory_in_gbs = var.instance_memory
    ocpus         = var.instance_ocpus
  }

  create_vnic_details {
    subnet_id        = var.create_vcn ? oci_core_subnet.semaphore_subnet[0].id : var.existing_subnet_id
    display_name     = "coolify-vnic"
    assign_public_ip = var.assign_public_ip
    assign_private_dns_record = true
  }

  source_details {
    source_type = "image"
    source_id   = local.instance_image_id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/cloud-init.yml", {
      ssh_public_key = var.ssh_public_key
    }))
  }

  freeform_tags = merge(var.common_tags, {
    "Instance" = "coolify-server"
  })

  timeouts {
    create = "60m"
  }
}

# Create Block Volume for KASM
resource "oci_core_volume" "kasm_volume" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  size_in_gbs         = 60
  display_name        = "kasm-volume"

  freeform_tags = merge(var.common_tags, {
    "VolumeFor" = "kasm-server"
  })
}

# Attach Block Volume to KASM Instance
resource "oci_core_volume_attachment" "kasm_attachment" {
  attachment_type = "iscsi"
  instance_id     = oci_core_instance.kasm.id
  volume_id       = oci_core_volume.kasm_volume.id
}

# Create Block Volume for Coolify
resource "oci_core_volume" "coolify_volume" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  size_in_gbs         = 100
  display_name        = "coolify-volume"

  freeform_tags = merge(var.common_tags, {
    "VolumeFor" = "coolify-server"
  })
}

# Attach Block Volume to Coolify Instance
resource "oci_core_volume_attachment" "coolify_attachment" {
  attachment_type = "iscsi"
  instance_id     = oci_core_instance.coolify.id
  volume_id       = oci_core_volume.coolify_volume.id
}
