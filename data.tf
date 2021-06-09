data "ibm_is_zones" "mzr" {
  region = var.region
}

data "ibm_resource_group" "group" {
  name = local.resource_group
}

data "ibm_is_ssh_key" "deploymentKey" {
  count = var.ssh_key != "" ? 1 : 0
  name  = var.ssh_key
}
