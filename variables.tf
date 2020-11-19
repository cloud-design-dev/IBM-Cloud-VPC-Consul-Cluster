# variable pdns_instance_name {}
variable region {}
variable resource_group {}
variable project_name {}
variable tags {
  default = ["ryantiffany"]
}

variable address_count {
  default = "256"
}

variable ibmcloud_api_key {}

variable ibmcloud_timeout {
  default = 900
}

variable consul_version {

}

variable profile {
  default = "cx2-2x4"
}

variable image {
  default = "ibm-ubuntu-20-04-minimal-amd64-2"
}

variable ssh_key {}

variable encrypt_key {}

variable "pdns_instance_name" {}