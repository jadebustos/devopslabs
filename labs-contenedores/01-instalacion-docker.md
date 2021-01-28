# Instalando docker

## Desplegando la máquina virtual

Iremos al directorio [terraform/kvm/docker](../terraform/kvm/docker) donde tenemos el plan de terraform para desplegar una máquina virtual en KVM.

La configuración de la máquina virtual, como claves ssh, dirección de red la haremos mediante [cloud-init](../doc-apoyo/cloud-init.md).

Hemos creado dos ficheros de cloud-init:

+ [Configuración de usuario](../terraform/kvm/docker/user_config.cfg)
+ [Configuracion de red](../terraform/kvm/docker/network_config.cfg)

Se puede consultar la configuración de cloud-init que admite el provider que estamos utilizando.

Una vez en el directorio para desplegar el plan de terraform:

```console
[jadebustos@beast docker]$ terraform init

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of lab.org/beast/libvirt from the dependency lock file
- Reusing previous version of hashicorp/template from the dependency lock file
- Installing hashicorp/template v2.2.0...
- Installed hashicorp/template v2.2.0 (signed by HashiCorp)
- Installing lab.org/beast/libvirt v0.6.3...
- Installed lab.org/beast/libvirt v0.6.3 (unauthenticated)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
[jadebustos@beast docker]$ terraform apply

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # libvirt_cloudinit_disk.commoninit will be created
  + resource "libvirt_cloudinit_disk" "commoninit" {
      + id             = (known after apply)
      + name           = "commoninit.iso"
      + network_config = <<-EOT
            #cloud-config
            # configuracion de red
            version: 2
            ethernets:
              ens3:
                dhcp4: false
                dhcp6: false
                addresses: [ 192.168.23.100/24 ] 
                gateway4: 192.168.23.1
                nameservers:
                  addresses: [ 192.168.1.200 ]
                search: [ 'jadbp.lab' ]
        EOT
      + pool           = "dockerstorage"
      + user_data      = <<-EOT
            #cloud-config
            # configuracion de usuarios
            #
            users:
              - name: terraform
                gecos: terraform created user
                sudo: ALL=(ALL) NOPASSWD:ALL
                groups: users
                ssh_import_id: None
                lock_passwd: true
                ssh_authorized_keys:
                  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDbV8HMtQ1D6qfn+pRINxB4x4QROfbxiS4TQNcffzvaID0baF/t951aRuvHaexy2QKKVb9u3RJSZfEuUvDJaFq2Oo5An8wWZqKvj6AC+yrBpD8D1M7E9uUuwqOfDwEu7pw7Otz+bUWD/x1mbJ4UUQ2fe+kFuiI/siILm7mAAAj7JfKDF3T6OdmHjzVKXHlWiuaLEXns0IkiogBrC4v83ziMt8nq6P3jbPDqI87UOi1Dkvi5vdI7maSBfBwE2vWJGSsnOovDu1kYQJOFje/AQx1sByve/36prBsW1zehfXl/3/tPJtQc8j7h+IaUg8ZRvDazncgirKuneQ6rvyXcfzDX jadebustos@beast.jadbp.lab
            
            runcmd:
              - hostnamectl set-hostname lab-docker.jadbp.lab
        EOT
    }

  # libvirt_domain.terraform-rhel will be created
  + resource "libvirt_domain" "terraform-rhel" {
      + arch        = (known after apply)
      + cloudinit   = (known after apply)
      + disk        = [
          + {
              + block_device = null
              + file         = null
              + scsi         = null
              + url          = null
              + volume_id    = (known after apply)
              + wwn          = null
            },
        ]
      + emulator    = (known after apply)
      + fw_cfg_name = "opt/com.coreos/config"
      + id          = (known after apply)
      + machine     = (known after apply)
      + memory      = 4096
      + name        = "lab-docker"
      + qemu_agent  = false
      + running     = true
      + vcpu        = 2

      + console {
          + source_host    = "127.0.0.1"
          + source_service = "0"
          + target_port    = "0"
          + target_type    = "serial"
          + type           = "pty"
        }
      + console {
          + source_host    = "127.0.0.1"
          + source_service = "0"
          + target_port    = "1"
          + target_type    = "virtio"
          + type           = "pty"
        }

      + graphics {
          + autoport       = true
          + listen_address = "127.0.0.1"
          + listen_type    = "address"
          + type           = "vnc"
        }

      + network_interface {
          + addresses    = (known after apply)
          + hostname     = (known after apply)
          + mac          = (known after apply)
          + network_id   = (known after apply)
          + network_name = "frontend"
        }
    }

  # libvirt_pool.dockerstorage will be created
  + resource "libvirt_pool" "dockerstorage" {
      + allocation = (known after apply)
      + available  = (known after apply)
      + capacity   = (known after apply)
      + id         = (known after apply)
      + name       = "dockerstorage"
      + path       = "/var/lib/libvirt/images/terraform/docker"
      + type       = "dir"
    }

  # libvirt_volume.centos8 will be created
  + resource "libvirt_volume" "centos8" {
      + format = "qcow2"
      + id     = (known after apply)
      + name   = "centos8"
      + pool   = "dockerstorage"
      + size   = (known after apply)
      + source = "/var/lib/libvirt/images/centos8-cloud-init-updated-20210117.qcow2"
    }

Plan: 4 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

libvirt_pool.dockerstorage: Creating...
libvirt_pool.dockerstorage: Creation complete after 5s [id=5bc710f4-815d-40f3-8507-e7d062a21e19]
libvirt_cloudinit_disk.commoninit: Creating...
libvirt_volume.centos8: Creating...
libvirt_volume.centos8: Creation complete after 6s [id=/var/lib/libvirt/images/terraform/docker/centos8]
libvirt_cloudinit_disk.commoninit: Creation complete after 7s [id=/var/lib/libvirt/images/terraform/docker/commoninit.iso;6004285f-4068-e92c-f3f3-d2a9b3cd5d28]
libvirt_domain.terraform-rhel: Creating...
libvirt_domain.terraform-rhel: Creation complete after 2s [id=292b86bd-1b18-4486-a7e1-717367498c7b]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
[jadebustos@beast docker]$
```

## Instalando docker

Para instalar docker y los ejemplos vamos al directorio [ansible](../ansible):

```console
[jadebustos@beast ansible]$ ansible-playbook -i hosts -l docker install-docker.yaml 
```
