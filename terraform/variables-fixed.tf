# Variables for OCI Infrastructure
# Authentication is handled via config file, not variables

# Required Variables (must be set in Semaphore environment)
variable "compartment_id" {
  description = "OCID of the compartment for resources"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

# Optional Variables with Defaults
variable "region" {
  description = "OCI region"
  type        = string
  default     = "us-ashburn-1"
}

variable "instance_shape" {
  description = "Shape for compute instances"
  type        = string
  default     = "VM.Standard.A1.Flex"  # ARM-based free tier
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

variable "create_vcn" {
  description = "Whether to create a new VCN"
  type        = bool
  default     = true
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

variable "fallback_image_ocid" {
  description = "Fallback image OCID if dynamic lookup fails"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    "ManagedBy" = "Terraform"
    "Project"   = "Semaphore"
  }
}