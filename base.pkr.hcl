packer {
  required_plugins {
    ibmcloud = {
      version = ">=v3.0.0"
      source  = "github.com/IBM/ibmcloud"
    }
  }
}

variable "ibmcloud_api_key" {
  type = string
  default = "${env("IBMCLOUD_API_KEY")}"
}

variable "region" {
  type = string
}

variable "resource_group_id" {
  type = string
}

variable "base_image_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "template_name" {
  type = string
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  name      = "${var.template_name}-${local.timestamp}"
}

source "ibmcloud-vpc" "starter" {
  api_key = "${var.ibmcloud_api_key}"
  region  = "${var.region}"

  subnet_id          = "${var.subnet_id}"
  resource_group_id  = "${var.resource_group_id}"
  security_group_id  = ""
  vsi_base_image_id  = "${var.base_image_id}"
  vsi_profile        = "cx2-2x4"
  vsi_interface      = "public"
  vsi_user_data_file = ""

  image_name   = "${local.name}"
  communicator = "ssh"
  ssh_username = "root"
  ssh_port     = 22
  ssh_timeout  = "15m"

  timeout = "30m"
}

build {
  name = "vpc-packer-builder"
  sources = [
    "source.ibmcloud-vpc.starter"
  ]

  provisioner "file" {
    source      = "./hashi.sh"
    destination = "/opt/hashi.sh"
  }

  provisioner "shell" {
    # execute_command = "{{.Vars}} bash '{{.Path}}'"
    inline = [
      "chmod +x /opt/hashi.sh",
      "/opt/hashi.sh"
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}



