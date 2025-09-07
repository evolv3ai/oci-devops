# OCI Provider Authentication Variables
variable "tenancy_ocid" {
  description = "OCI Tenancy OCID"
  type        = string
}

variable "user_ocid" {
  description = "OCI User OCID"
  type        = string
}

variable "fingerprint" {
  description = "OCI API Key Fingerprint"
  type        = string
}

variable "private_key_path" {
  description = "Path to OCI Private Key"
  type        = string
  default     = "/oci/oci_api_key.pem"
}

variable "region" {
  description = "OCI Region"
  type        = string
  default     = "us-ashburn-1"
}

variable "auth_token" {
  description = "OCI Auth Token (optional)"
  type        = string
  default     = ""
}

# Resource Configuration Variables
variable "compartment_id" {
  description = "OCI Compartment OCID for resources"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH Public Key for instance access"
  type        = string
}

variable "oci_cli_config" {
  description = "Path to OCI CLI config file"
  type        = string
  default     = "/oci/config"
}

# Instance Configuration Variables
variable "instance_shape" {
  description = "Shape for compute instances"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs for flexible instances"
  type        = number
  default     = 2
}

variable "instance_memory" {
  description = "Memory in GB for flexible instances"
  type        = number
  default     = 12
}

# Network Configuration Variables
variable "create_vcn" {
  description = "Whether to create a new VCN"
  type        = bool
  default     = true
}

variable "vcn_cidr" {
  description = "CIDR block for VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "existing_subnet_id" {
  description = "Existing subnet ID if not creating VCN"
  type        = string
  default     = ""
}

variable "assign_public_ip" {
  description = "Whether to assign public IPs to instances"
  type        = bool
  default     = true
}

# Optional Fallback Variables
variable "fallback_image_ocid" {
  description = "Fallback image OCID if dynamic lookup fails"
  type        = string
  default     = ""
}

# Tagging Variables
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    "ManagedBy" = "Terraform"
    "Project"   = "Semaphore"
  }
}