variable "pool_path" {
  type = string
  description = "directorio donde se almacenara el qcow2"
  default = "/var/lib/libvirt/images/terraform/podman"
}

variable "vm_name" {
  type = string
  description = "nombre de la maquina virtual"
  default = "lab-podman"
}

variable "qcow2_image" {
  type = string
  description = "imagen qcow2 para desplegar"
  #default = "https://fqdn/centos8-cloud-init-updated-20210117.qcow2"
  default = "/var/lib/libvirt/images/centos8-python36-cloud_init-updated-20210117.qcow2"
}

variable "cpu" {
  type = number
  description = "vcpus"
  default = 2
}

variable "memory" {
  type = number
  description = "memoria en megas"
  default = 4096
}

variable "network_name" {
  type = string
  description = "red para la maquina virtual"
  default = "frontend"
}

