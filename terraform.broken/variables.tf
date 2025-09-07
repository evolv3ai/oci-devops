# Input Variables for OCI Terraform Configuration

# OCI Provider Configuration
variable "tenancy_ocid" {
  description = "OCID of the tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of the public key"
  type        = string
}

variable "private_key_path" {
  description = "Path to the private key"
  type        = string
}

variable "region" {
  description = "OCI region"
  type        = string
  default     = "us-ashburn-1"
}

variable "compartment_id" {
  description = "OCID of the compartment"
  type        = string
}

# Network Configuration
variable "create_vcn" {
  description = "Whether to create a new VCN or use existing"
  type        = bool
  default     = true
}

variable "existing_subnet_id" {
  description = "OCID of existing subnet (if create_vcn is false)"
  type        = string
  default     = null
}

# Instance Configuration
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
}

variable "instance_name_prefix" {
  description = "Prefix for instance names"
  type        = string
  default     = "semaphore-instance"
}

variable "instance_shape" {
  description = "Shape of the instance"
  type        = string
  default     = "VM.Standard.A1.Flex" # Always Free tier Ampere A1 eligible
}

variable "instance_memory" {
  description = "Memory in GBs for flexible shapes"
  type        = number
  default     = 12
}

variable "instance_ocpus" {
  description = "Number of OCPUs for flexible shapes"
  type        = number
  default     = 2
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the instance"
  type        = bool
  default     = true
}

# SSH Configuration
variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

# Tagging
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "development"
    Project     = "semaphore-automation"
    CreatedBy   = "terraform"
  }
}

# Application Configuration
variable "app_port" {
  description = "Port for application"
  type        = number
  default     = 8080
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

# Fallback Image Configuration
variable "fallback_image_ocid" {
  description = "Fallback image OCID if dynamic lookup fails"
  type        = string
  default     = ""
}
