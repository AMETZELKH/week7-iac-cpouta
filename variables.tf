variable "project_network" {
  description = "Name of the existing project network in cPouta"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "~/.ssh/week7_ed25519.pub"
}

variable "name_prefix" {
  description = "Prefix used for resources created by this project"
  type        = string
  default     = "week7"
}

variable "ssh_allowed_cidr" {
  description = "CIDR range allowed to access the VM through SSH"
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr, 0))
    error_message = "ssh_allowed_cidr must be a valid CIDR address, for example 203.0.113.45/32."
  }
}

variable "image_name" {
  description = "Name of the operating system image"
  type        = string
  default     = "Ubuntu-24.04"
}

variable "flavor_name" {
  description = "Name of the OpenStack VM flavor"
  type        = string
  default     = "standard.tiny"
}

variable "student_name" {
  description = "Student name displayed on the web page"
  type        = string
}

variable "page_message" {
  description = "Message displayed on the web page"
  type        = string
  default     = "Welcome!"
}