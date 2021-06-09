module "vpc" {
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Module.git"
  name           = var.name
  resource_group = var.resource_group
  tags           = concat(var.tags, ["vpc:${var.name}-vpc"])
}

module "public_gateway" {
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Public-Gateway-Module.git"
  name           = "${var.name}-pubgw"
  zone           = var.zone
  vpc            = module.vpc.id
  resource_group = var.resource_group
  tags           = concat(var.tags, ["vpc:${var.name}-vpc", "zone:${var.zone}"])
}

module "subnet" {
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Subnet-Module.git"
  name           = "${var.name}-subnet"
  resource_group = var.resource_group
  address_count  = var.address_count
  vpc            = module.vpc.id
  zone           = var.zone
  public_gateway = module.public_gateway.id
  tags           = concat(var.tags, ["vpc:${var.name}-vpc", "zone:${var.zone}"])
}