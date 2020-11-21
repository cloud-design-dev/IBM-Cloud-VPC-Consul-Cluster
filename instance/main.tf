data ibm_is_image image {
  name = var.image_name
}

resource "ibm_is_instance" "instance" {
  name           = var.name
  vpc            = var.vpc_id
  zone           = var.zone
  profile        = var.profile_name
  image          = data.ibm_is_image.image.id
  keys           = [var.ssh_key]
  resource_group = var.resource_group

  user_data = templatefile("${path.module}/init.yml", { generated_key = var.public_key, password_hash = var.password_hash })

  primary_network_interface {
    subnet          = var.subnet_id
    security_groups = [var.security_group_id]
  }

  boot_volume {
    name = "${var.name}-boot"
  }

  tags = concat(var.tags, [var.zone, "instance"])
}