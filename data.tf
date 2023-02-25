data "ibm_is_zones" "regional" {
  region = var.region
}

data "ibm_is_ssh_key" "sshkey" {
  count = var.existing_ssh_key != "" ? 1 : 0
  name  = var.existing_ssh_key
}

data "ibm_is_image" "base" {
  name = var.base_image
}

data "packer_version" "version" {}

data "packer_files" "base" {
  file = "${path.module}/base.pkr.hcl"
}

data "local_file" "packer_manifest" {
  depends_on = [
    packer_image.hashistack
  ]
  filename = "manifest.json"
}

data "ibm_resource_instance" "cos" {
  count = var.existing_cos_instance != "" ? 1 : 0
  name  = var.existing_cos_instance
}