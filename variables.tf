variable "ibmcloud_api_key" {
  description = "IBM Cloud API key."
  type        = string
  default     = ""
}

variable "region" {
  description = "IBM Cloud VPC region where resources will be deployed."
  type        = string
  default     = ""
}

variable "resource_group" {
  default = ""
}

variable "name" {}

variable "tags" {
  default = ["owner:ryantiffany"]
}

variable "address_count" {
  default = "256"
}

variable "allow_ssh_from" {
  default = ""
}

variable "ibmcloud_timeout" {
  default = 900
}

variable "profile" {
  default = "cx2-2x4"
}

variable "image" {
  type        = string
  description = "Default OS Image to use for consul instance"
  default     = "ibm-ubuntu-20-04-minimal-amd64-2"
}

variable "ssh_key" {
  default = ""
}

variable "encrypt_key" {}


variable "create_public_ip" {
  type        = bool
  description = "Set whether to allocate a public IP address for the bastion instance. Default is `true`"
  default     = true
}
