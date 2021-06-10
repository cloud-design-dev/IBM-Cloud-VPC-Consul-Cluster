variable "name" {}
variable "vpc_id" {}
variable "bastion_security_group" {}
variable "resource_group" {}
variable "security_group_rules" {
  description = "List of security group rules to set on the bastion security group in addition to the SSH rules"
  default = [
    {
      name      = "consul_tcp_dns_in"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 8600
        port_max = 8600
      }
    },
    {
      name      = "consul_udp_dns_in"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      udp = {
        port_min = 8600
        port_max = 8600
      }
    },
    {
      name      = "consul_udp_in"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      udp = {
        port_min = 8301
        port_max = 8302
      }
    },
    {
      name      = "consul_tcp_in"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 8300
        port_max = 8302
      }
    },
    {
      name      = "consul_http"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 8500
        port_max = 8500
      }
    },
    {
      name      = "consul_icmp_in"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      icmp = {
        type = 8
      }
    },
    {
      name      = "allow_outbound"
      direction = "outbound"
      remote    = "0.0.0.0/0"
    }
  ]
}