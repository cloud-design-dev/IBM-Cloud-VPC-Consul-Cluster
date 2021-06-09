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

variable "existing_resource_group" {
  type        = string
  description = "(Optional) The name of an existing Resource Group to use for deployed resources. If none provided, one will be created for you."
  default     = ""
}

variable "existing_vpc_name" {
  type        = string
  description = "(Optional) The name of an existing VPC to use for deployed resources. If none provided, one will be created for you. If you use an existing VPC you must also specify an existing Subnet."
  default     = ""
}

variable "existing_subnet_name" {
  type        = string
  description = "(Optional) The name of an existing Subnet to use for deployed resources. If none provided, one will be created for you. If you use an existing Subnet you must also specify an existing VPC."
  default     = ""
}

variable "name" {
  type        = string
  description = "Identifier that will be prepended to all resource names."
}

variable "tags" {
  default = []
}

variable "owner" {
  default = "ryantiffany"
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
  type        = string
  description = "The name of an existing SSH key in the VPC region that will be added to all compute instances."
  default     = ""
}

variable "encrypt_key" {}


variable "create_public_ip" {
  type        = bool
  description = "Set whether to allocate a public IP address for the bastion instance. Default is `true`"
  default     = true
}

variable "commit" {
  type    = string
  default = ""
}