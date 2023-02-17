# variable "ibmcloud_api_key" {
#   description = "IBM Cloud API key."
#   type        = string
#   default     = ""
# }

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



variable "project_prefix" {
  type        = string
  description = "Identifier that will be prepended to all resource names."
}



variable "owner" {
  type        = string
  description = "Identifier for project resources."
  default     = ""
}


# variable "allow_ssh_from" {
#   type        = string
#   description = "(Optional) An IP Address, CIDR block, or VPC Security group that will be allowed to access the bastion via SSH."
#   default     = ""
# }

# variable "ibmcloud_timeout" {
#   description = "IBM Cloud API timeout."
#   default     = 900
# }

# variable "profile" {
#   type        = string
#   description = "Default instance size for compute nodes. Run `ibmcloud in-prs` to see available options."
#   default     = "cx2-2x4"
# }

# variable "image" {
#   type        = string
#   description = "Default OS Image to use for consul instance"
#   default     = "ibm-ubuntu-20-04-minimal-amd64-2"
# }

variable "existing_ssh_key" {
  type        = string
  description = "The name of an existing SSH key in the VPC region that will be added to all compute instances."
  default     = ""
}

variable "classic_access" {
  description = "Allow classic access to the VPC."
  type        = bool
  default     = false
}

variable "default_address_prefix" {
  description = "The address prefix to use for the VPC. Default is set to auto."
  type        = string
  default     = "auto"
}