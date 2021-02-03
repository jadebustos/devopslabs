# Ansible

En este directorio se encuentran los playbooks para desplegar y configurar los laboratorios. 

Una vez desplegadas las máquinas virtuales modifica el fichero de inventario [hosts](hosts) la máquina virtual para hacer los laboratorios de docker y la máquina para los laboratorios de podman.

Configura un usuario en dichas máquinas para hacer ssh autenticándose con clave pública y con acceso a sudo sin contraseña tal y como se indica [aquí](../labs-ansible/00-primeros-pasos.md).

Para configurar los laboratorios:

```console
[user@controller ansible]$ ansible-playbook -i hosts -l docker install-docker.yaml
...
[user@controller ansible]$ ansible-playbook -i hosts -l podman install-podman.yaml
...
[user@controller ansible]$
```