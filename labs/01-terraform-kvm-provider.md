# Instalando el provider de KVM para terraform

KVM no se encuentra entre los proveedores distribuidos con terraform, con lo cual podemos descargarlo desde [aquí](https://github.com/dmacvicar/terraform-provider-libvirt/releases/).

En este caso descargaremos la versión 0.63 para [Fedora](https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v0.6.3/terraform-provider-libvirt-0.6.3+git.1604843676.67f4f2aa.Fedora_32.x86_64.tar.gz). La descargaremos en tgz aunque hay versiones paquetizadas en RPM y DEB.


```console
[jadebustos@beast tmp]$ wget https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v0.6.3/terraform-provider-libvirt-0.6.3+git.1604843676.67f4f2aa.Fedora_32.x86_64.tar.gz
[jadebustos@beast tmp]$ mkdir -p ~/.terraform.d/plugins/lab.org/beast/libvirt/0.6.3/linux_amd64/
[jadebustos@beast tmp]$ tar zxf terraform-provider-libvirt-0.6.3+git.1604843676.67f4f2aa.Fedora_32.x86_64.tar.gz -C ~/.terraform.d/plugins/lab.org/beast/libvirt/0.6.3/linux_amd64/ 
[jadebustos@beast tmp]$ 
```

En el directorio donde vamos a crear el plan de terraform creamos el fichero **libvirt.tf**:

```
# configurar provider
terraform {
  required_providers {
    libvirt = {
      version = "0.6.3"
      source  = "lab.org/beast/libvirt"
    }
  }
}

# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}
```

A continuación:

```console
[jadebustos@beast kvm]$ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding lab.org/beast/libvirt versions matching "0.6.3"...
- Installing lab.org/beast/libvirt v0.6.3...
- Installed lab.org/beast/libvirt v0.6.3 (unauthenticated)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
[jadebustos@beast kvm]$ terraform version
Terraform v0.14.4
+ provider lab.org/beast/libvirt v0.6.3
[jadebustos@beast kvm]$
```

El plugin es accesible y ya podemos usarlo.

Podemos ver los providers que requiere el plan:

```console
[jadebustos@beast kvm]$ terraform providers

Providers required by configuration:
.
└── provider[lab.org/beast/libvirt] 0.6.3

[jadebustos@beast kvm]$ 
```

Ahora completamos el [plan](../terraform/kvm/docker/libvirt.tf).

Para ejecutar el plan:

```console
[jadebustos@beast kvm]$ terraform init
...
[jadebustos@beast kvm]$ terraform apply
...
  Enter a value: yes

libvirt_pool.dockerstorage: Creating...
libvirt_pool.dockerstorage: Creation complete after 5s [id=faad61a0-e7ff-4373-a582-c531e2d6534b]
libvirt_volume.rhel8: Creating...
libvirt_volume.rhel8: Creation complete after 3s [id=/var/lib/libvirt/terraform/rhel8]
libvirt_domain.terraform-rhel: Creating...
libvirt_domain.terraform-rhel: Creation complete after 0s [id=510253d2-618c-4249-a50d-36e08a6ecf48]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
[jadebustos@beast kvm]$ 
```

Estado del plan:

```console
[jadebustos@beast kvm]$ terraform state list
libvirt_domain.terraform-rhel
libvirt_pool.dockerstorage
libvirt_volume.rhel8
[jadebustos@beast kvm]$ 
```

Podemos ver información con mayor nivel de detalle:

```console
[jadebustos@beast kvm]$ terraform state pull
{
  "version": 4,
  "terraform_version": "0.14.4",
  "serial": 27,
  "lineage": "d3c257a3-c9b5-e6b5-d438-1974ad552492",
  "outputs": {},
  "resources": [
    {
      "mode": "managed",
      "type": "libvirt_domain",
      "name": "terraform-rhel",
      "provider": "provider[\"lab.org/beast/libvirt\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "arch": "x86_64",
            "autostart": false,
            "boot_device": [],
            "cloudinit": null,
            "cmdline": null,
            "console": [
              {
                "source_host": "127.0.0.1",
                "source_path": "",
                "source_service": "0",
                "target_port": "0",
                "target_type": "serial",
                "type": "pty"
              },
              {
                "source_host": "127.0.0.1",
                "source_path": "",
                "source_service": "0",
                "target_port": "1",
                "target_type": "virtio",
                "type": "pty"
              }
            ],
            "coreos_ignition": null,
            "cpu": null,
            "description": "",
            "disk": [
              {
                "block_device": "",
                "file": "",
                "scsi": false,
                "url": "",
                "volume_id": "/var/lib/libvirt/terraform/rhel8",
                "wwn": ""
              }
            ],
            "emulator": "/usr/bin/qemu-system-x86_64",
            "filesystem": [],
            "firmware": "",
            "fw_cfg_name": "opt/com.coreos/config",
            "graphics": [
              {
                "autoport": true,
                "listen_address": "127.0.0.1",
                "listen_type": "address",
                "type": "spice"
              }
            ],
            "id": "510253d2-618c-4249-a50d-36e08a6ecf48",
            "initrd": "",
            "kernel": "",
            "machine": "pc",
            "memory": 4096,
            "metadata": null,
            "name": "terraform-rhel",
            "network_interface": [
              {
                "addresses": [],
                "bridge": "",
                "hostname": "",
                "mac": "52:54:00:92:D0:5B",
                "macvtap": "",
                "network_id": "49eee855-d342-46c3-9ed3-b8d1758814cd",
                "network_name": "crc",
                "passthrough": "",
                "vepa": "",
                "wait_for_lease": false
              }
            ],
            "nvram": [],
            "qemu_agent": false,
            "running": true,
            "timeouts": null,
            "vcpu": 2,
            "video": [],
            "xml": []
          },
          "sensitive_attributes": [],
          "private": "eyJlMmJmYjczMC1lY2FhLTExZTYtOGY4OC0zNDM2M2JjN2M0YzAiOnsiY3JlYXRlIjozMDAwMDAwMDAwMDB9fQ==",
          "dependencies": [
            "libvirt_pool.dockerstorage",
            "libvirt_volume.rhel8"
          ]
        }
      ]
    },
    {
      "mode": "managed",
      "type": "libvirt_pool",
      "name": "dockerstorage",
      "provider": "provider[\"lab.org/beast/libvirt\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "allocation": 7762993152,
            "available": null,
            "capacity": 21464350720,
            "id": "faad61a0-e7ff-4373-a582-c531e2d6534b",
            "name": "dockerstorage",
            "path": "/var/lib/libvirt/terraform",
            "type": "dir",
            "xml": []
          },
          "sensitive_attributes": [],
          "private": "bnVsbA=="
        }
      ]
    },
    {
      "mode": "managed",
      "type": "libvirt_volume",
      "name": "rhel8",
      "provider": "provider[\"lab.org/beast/libvirt\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "base_volume_id": null,
            "base_volume_name": null,
            "base_volume_pool": null,
            "format": "qcow2",
            "id": "/var/lib/libvirt/terraform/rhel8",
            "name": "rhel8",
            "pool": "dockerstorage",
            "size": 21474836480,
            "source": "/var/lib/libvirt/images/rhel8.0-updated-20190530.qcow2",
            "xml": []
          },
          "sensitive_attributes": [],
          "private": "bnVsbA==",
          "dependencies": [
            "libvirt_pool.dockerstorage"
          ]
        }
      ]
    }
  ]
}

[jadebustos@beast kvm]$ 
```
