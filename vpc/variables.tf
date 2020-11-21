variable zone {}
variable name {}
variable tags {}
variable resource_group {}

variable address_count {
  default = [
    {
      bastion = 8
      consul = 64
    }
  ]
}

variable remote_ip {}