# Requisitos

Antes de empezar los labs será necesario actualizar la máquina a último nivel:

```console
[root@docker ~]# dnf update -y
```

## Instalación de ansible

Se proporciona un playbook que se encargar de desplegar el entorno y otro para desplegar los ejemplos y por ello es necesario tener instalado ansible.

Si no lo tuvieramos sería necesario instalarlo:

```console
[root@docker ~]# dnf install epel-release -y
[root@docker ~]# dnf install ansible -y
[root@docker ~]#
```