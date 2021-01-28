# Instalando podman, buildah y skopeo

## Desplegando la máquina virtual

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

## Instalando podman

Para instalar podman vamos al directorio [ansible](../ansible):

```console
[jadebustos@beast ansible]$ ansible-playbook -i hosts -l podman install-podman.yaml 
```

