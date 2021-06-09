data "ibm_is_zones" "mzr" {
  region = var.region
}

data "ibm_resource_group" "group" {
  count = var.existing_resource_group != "" ? 1 : 0
  name  = var.existing_resource_group
}

data "ibm_is_ssh_key" "deploymentKey" {
  count = var.ssh_key != "" ? 1 : 0
  name  = var.ssh_key
}

data "ibm_is_vpc" "vpc" {
  count = var.existing_vpc_name != "" ? 1 : 0
  name  = var.existing_vpc_name
}


data "ibm_is_subnet" "subnet" {
  count = var.existing_subnet_name != "" ? 1 : 0
  name  = var.existing_subnet_name
}