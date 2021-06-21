# Instalando podman, buildah y skopeo

## Instalando podman con ansible

Si ya tenemos desplegada una máquina para instalar podman vamos al directorio [ansible](../ansible):

```console
[root@podman ~]# git clone https://github.com/jadebustos/devopslabs.git
[root@podman ~]# cd devopslabs/ansible
[root@podman ansible]# ansible-playbook -i hosts install-podman.yaml 
...
[root@podman ansible]#
```
## Desplegando la máquina virtual con terraform

Se incluye un plan de Terraform para desplegar la máquina de podman sobre KVM.

Iremos al directorio [terraform/kvm/podman](../terraform/kvm/podman) donde tenemos el plan de terraform para desplegar una máquina virtual en KVM.

La configuración de la máquina virtual, como claves ssh, dirección de red la haremos mediante [cloud-init](../doc-apoyo/cloud-init.md).

Hemos creado dos ficheros de cloud-init:

+ [Configuración de usuario](../terraform/kvm/podman/user_config.cfg)
+ [Configuracion de red](../terraform/kvm/podman/network_config.cfg)

Se puede consultar la configuración de cloud-init que admite el provider que estamos utilizando.

Una vez en el directorio para desplegar el plan de terraform:

```console
[jadebustos@beast podman]$ terraform init
...
[jadebustos@beast podman]$ terraform apply
...
  Enter a value: yes
...
[jadebustos@beast podman]$
```

