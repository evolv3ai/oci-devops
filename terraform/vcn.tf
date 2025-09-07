# VCN Resources - Deployed based on workspace configuration

resource "oci_core_vcn" "main" {
  count = local.current_config.deploy_vcn ? 1 : 0

  compartment_id = var.compartment_id
  cidr_blocks    = [local.current_config.vcn_cidr]
  display_name   = "${terraform.workspace}-${local.current_config.vcn_name}-${formatdate("YYYYMMDD", timestamp())}"
  dns_label      = "${replace(terraform.workspace, "-", "")}vcn"

  freeform_tags = merge(
    var.common_tags,
    {
      "Workspace"   = terraform.workspace
      "Environment" = terraform.workspace
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Internet Gateway
resource "oci_core_internet_gateway" "main" {
  count = local.current_config.deploy_vcn ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main[0].id
  display_name   = "${terraform.workspace}-igw"
  enabled        = true

  freeform_tags = merge(
    var.common_tags,
    {
      "Workspace" = terraform.workspace
    }
  )
}

# Public Subnet (for test-vcn-only workspace, this is all we need)
resource "oci_core_subnet" "public" {
  count = local.current_config.deploy_vcn ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main[0].id
  cidr_block     = cidrsubnet(local.current_config.vcn_cidr, 8, 1)
  display_name   = "${terraform.workspace}-public-subnet"
  dns_label      = "public"
  
  # Make it public subnet
  prohibit_public_ip_on_vnic = false
  
  freeform_tags = merge(
    var.common_tags,
    {
      "Workspace" = terraform.workspace
      "Type"      = "public"
    }
  )
}

# Route Table for Public Subnet
resource "oci_core_route_table" "public" {
  count = local.current_config.deploy_vcn ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main[0].id
  display_name   = "${terraform.workspace}-public-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.main[0].id
  }

  freeform_tags = merge(
    var.common_tags,
    {
      "Workspace" = terraform.workspace
    }
  )
}