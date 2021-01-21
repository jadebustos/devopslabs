# https://www.terraform.io/docs/cloud/run/install-software.html
# https://www.hashicorp.com/blog/automatic-installation-of-third-party-providers-with-terraform-0-13
# https://learn.hashicorp.com/tutorials/terraform/provider-use?utm_offer=ARTICLE_PAGE&utm_source=WEBSITE&utm_medium=WEB_BLOG

# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/examples/

# configurar provider
terraform {
  required_providers {
    libvirt = {
      version = "0.6.3"
      source  = "lab.org/beast/libvirt"
    }
  }
}

# inicializamos el provider
provider "libvirt" {
#  uri = "qemu+ssh://youruser@fqdn/system"
  uri = "qemu:///system"
}

# definimos el pool donde vamos a crear la vm
resource "libvirt_pool" "dockerstorage" {
  name = "dockerstorage"
  type = "dir"
  path = var.pool_path
}

# configuracion de usuario con cloud_init
data "template_file" "user_data" {
   template = file("${path.module}/user_config.cfg")
}

# configuracion de red con cloud_init
data "template_file" "network_data" {
   template = file("${path.module}/network_config.cfg")
}

# for more info about paramater check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/cloudinit.html.markdown
# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_data.rendered
  pool           = libvirt_pool.dockerstorage.name
}

# definimos la imagen que vamos a clonar
resource "libvirt_volume" "centos8" {
  name   = "centos8"
  pool   = libvirt_pool.dockerstorage.name
  source = var.qcow2_image
  format = "qcow2"
}

# creamos la vm
resource "libvirt_domain" "terraform-centos" {
  name   = var.vm_name
  memory = var.memory
  vcpu   = var.cpu

  # mapeamos datos para cloudinit
  cloudinit = libvirt_cloudinit_disk.commoninit.id

  # definimos el nombre de la red a la que vamos a asignar la vm
  network_interface {
    network_name = var.network_name
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  # definimos el disco que vamos a asignar (disco de arranque)
  disk {
    volume_id = libvirt_volume.centos8.id
  }
  
  # definimos el protocolo gráfico para conectarse a la vm
  graphics {
  #  type        = "spice"
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }
}
