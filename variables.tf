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
  type        = list(string)
  description = "Default set of tags to add to all deployed resources."
  default     = []
}

variable "owner" {
  type        = string
  description = "Identifier for project resources."
  default     = ""
}


variable "allow_ssh_from" {
  type        = string
  description = "(Optional) An IP Address, CIDR block, or VPC Security group that will be allowed to access the bastion via SSH."
  default     = ""
}

variable "ibmcloud_timeout" {
  description = "IBM Cloud API timeout."
  default     = 900
}

variable "profile" {
  type        = string
  description = "Default instance size for compute nodes. Run `ibmcloud in-prs` to see available options."
  default     = "cx2-2x4"
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

variable "encrypt_key" {
  type        = string
  description = "TThe Consul Encrypt Key. See README if you need to generate a key."
  default     = ""
}


variable "create_public_ip" {
  type        = bool
  description = "Set whether to allocate a public IP address for the bastion instance. Default is `true`"
  default     = true
}

variable "commit" {
  type        = string
  description = "Github SHA for commit. This is used for tracking purposes and will be removed at some point."
  default     = ""
}