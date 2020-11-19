resource ibm_is_public_gateway gateway {
  count          = length(data.ibm_is_zones.mzr.zones)
  name           = "${local.name}-${data.ibm_is_zones.mzr.zones[count.index]}-gateway"
  vpc            = ibm_is_vpc.vpc.id
  zone           = data.ibm_is_zones.mzr.zones[count.index]
  resource_group = data.ibm_resource_group.project_group.id
}

resource ibm_is_subnet subnet {
  count                    = length(data.ibm_is_zones.mzr.zones)
  name                     = "${local.name}-${data.ibm_is_zones.mzr.zones[count.index]}-subnet"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = data.ibm_is_zones.mzr.zones[count.index]
  total_ipv4_address_count = var.address_count
  public_gateway           = ibm_is_public_gateway.gateway[count.index].id
  resource_group           = data.ibm_resource_group.project_group.id
}