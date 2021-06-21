# Ansible

En este directorio se encuentran los playbooks para desplegar y configurar los laboratorios. 

Instala [ansible en las máquinas](../labs/ansible/.md) y ejecutando el playbook correspondiente se copiaran los ejemplos para su uso.

## Laboratorios de ansible

Clona este repositorio en el HOME de tu usuario en la máquinas que usuarás como ansible controller:

```console
[user@ansiblecontroller ~]$ git clone https://github.com/jadebustos/devopslabs.git
...
[user@ansiblecontroller ~]$
```

Ejecuta el playbook para instalar los ejemplos:

```console
[user@ansiblecontroller ~]$ cd devopslabs/ansible
[user@ansiblecontroller ansible]$ ansible-playbook -i hosts deploy-ansible-examples.yaml
...
[user@ansiblecontroller ansible]$
```

Los ejemplos se encontrarán en el directorio **~/ansible**. De esta forma podrás hacer pull para sincronizar el repositorio y ejecutando el playbook actualizará el contenido del directorio **~/ansible** con la última versión.

## Laboratorios de contenedores

Para configurar los laboratorios de **docker**, conectate a la máquina que vas a utilizar y ejecuta:

```console
[root@docker ~]# git clone https://github.com/jadebustos/devopslabs.git
...
[root@docker ~]# cd devopslabs/ansible
[root@docker ansible]# ansible-playbook -i hosts install-docker.yaml
...
[root@docker ansible]#
```
Para configurar los laboratorios de **podman**, conectate a la máquina que vas a utilizar y ejecuta:

```console
[root@podman ~]# git clone https://github.com/jadebustos/devopslabs.git
...
[root@podman ~]# cd devopslabs/ansible
[root@podman ansible]# ansible-playbook -i hosts install-podman.yaml
...
[root@podman ansible]#
```

Se configurarán las máquinas con docker y podman, y se copiarán los ejemplos en el directorio **/root/build/**.