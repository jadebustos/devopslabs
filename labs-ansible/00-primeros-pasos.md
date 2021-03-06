# Primeros pasos con Ansible

Necesitaremos dos máquinas:

+ **Ansible controller**, será la máquina donde se instalará ansible.
+ **Ansible client**, será la máquina donde ejecutaremos tareas con ansible.

## Instalación de Ansible (CentOS)

Para instalar ansible será necesario configurar el repositorio EPEL en la máquina que tendrá el role de ansible controller:

```console
[root@ansiblectrl ~]# dnf install epel-release -y
...
[root@ansiblectrl ~]#
```

Una vez configurado el repositorio podremos instalar ansible y otras utilidades:

```console
[root@ansiblectrl ~]# dnf install ansible git tree jq -y
...
[root@ansiblectrl ~]#
```

Será necesario que en el nodo cliente se encuentre instalado el paquete **python36**:

```console
[root@ansibleclient ~]# dnf install python36 -y
...
[root@ansibleclient ~]#
```

## Creación de usuarios

Necesitaremos crear un usuario en cada una de las máquinas.

En el controller crearemos un usuario que será con el que lanzaremos las tareas con ansible:

```console
[root@ansiblectrl ~]# useradd -md /home/jadebustos jadebustos
[root@ansiblectrl ~]# passwd jadebustos
Changing password for user jadebustos.
New password: 
BAD PASSWORD: The password is shorter than 8 characters
Retype new password: 
passwd: all authentication tokens updated successfully.
[root@ansiblectrl ~]#
```

En el cliente crearemos un usuario que será utilizado por ansible para conectarse y ejecutar tareas:

```console
[root@ansibleclient ~]# useradd -md /home/ansible ansible
[root@ansibleclient ~]# passwd ansible
Changing password for user ansible.
New password: 
BAD PASSWORD: The password is shorter than 8 characters
Retype new password: 
passwd: all authentication tokens updated successfully.
[root@ansibleclient ~]# 
```

## Acceso a los nodos

Para poder acceder a los nodos gestionados por ansible y poder ejecutar tareas será necesario configurar el acceso mediante clave pública.

Para ello desde el controller de ansible, equipo desde el que ejecutaremos ansible, deberemos crear una clave ssh en la cuenta de usuario desde la que ejecutaremos ansible.

Para comprobar si tenemos creadas claves:

```console
[jadebustos@ansiblectrl ~]$ ls -lh .ssh/*
-rw-------. 1 jadebustos jadebustos 1.9K Oct 14 20:00 .ssh/authorized_keys
-rw-------. 1 jadebustos jadebustos 1.7K Apr 15  2018 .ssh/id_rsa
-rw-r--r--. 1 jadebustos jadebustos  408 Jan 17 10:50 .ssh/id_rsa.pub
-rw-------. 1 jadebustos jadebustos 4.1K Jan 24 16:11 .ssh/known_hosts
[jadebustos@ansiblectrl ~]$ 
```

Si no tuvieramos ficheros **.pub** (clave pública) y otro con el mismo nombre pero sin la "extensión" **.pub** deberemos generar las claves ejecutando:

```console
[jadebustos@ansiblectrl ~]$ ssh-keygen -t rsa -b 4096
Generating public/private rsa key pair.
Enter file in which to save the key (/home/jadebustos/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in id_rsa
Your public key has been saved in id_rsa.pub
The key fingerprint is:
SHA256:d6ePc0yE/+ZhkgTgxPqpNn4iEV5vmbUnCUFt0YXPPUc jadebustos@ansiblectrl.jadbp.lab
The key's randomart image is:
+---[RSA 4096]----+
|        o+..o o. |
|        oo.o o  E|
|        ..o. .o..|
|     . o . .o .+o|
|    . o S B ++. o|
|     o   O =.++  |
|      . o   += + |
|     . = .  .o= +|
|      +.+   .o.o.|
+----[SHA256]-----+
[jadebustos@ansiblectrl ~]$
```

> ![IMPORTANT](../imgs/important-icon.png) No poner contraseña a la clave para que ansible se pueda conectar de forma desasistida.

> ![IMPORTANT](../imgs/important-icon.png) Si se cambia el nombre del fichero para las claves **id_rsa** cuando queramos utilizarla deberemos especificar el fichero con el flag **-i nombre_fichero_claves**.

Una vez generada tendremos que copiar la clave pública a los hosts que queramos gestionar y a la cuenta del usuario con el que se conectará ansible. Como vamos a lanzar tareas desde el  controller de ansible con el usuario **jadebustos** al equipo client **nodo1** conectándonos con el usuario **ansible** a dicho nodo podemos copiar la clave:

```console
[jadebustos@ansiblectrl ~]$ ssh-copy-id -i .ssh/id_rsa.pub ansible@ansibleclient
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: ".ssh/id_rsa.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
ansible@ansibleclient's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'ansible@ansibleclient'"
and check to make sure that only the key(s) you wanted were added.

[jadebustos@ansiblectrl ~]$
```

Si despliegas las máquinas con terraform puedes utilizar **cloud-init** tanto para crear el usuario como para configurar la clave pública. En el código para desplegar las imágenes del laboratorio se pueden ver [ejemplos](../terraform/kvm/docker/user_config.cfg):

```yaml
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
  - hostnamectl set-hostname lab-docker.frontend.lab
```

## Escalado de privilegios

Si queremos ejecutar tareas privilegiadas con ansible necesitaremos escalar privilegios. Para ello será necesario configurar en sudoers que el usuario que va a ejecutar las tareas de ansible pueda escalar privilegios sin autenticación. Si ese usuario fuera el usuario ansible tendríamos que crear el fichero **/etc/sudoers.d/ansible** con el siguiente contenido:

```bash
ansible ALL=(ALL) NOPASSWD:ALL
```

Si despliegas las máquinas con terraform puedes utilizar **cloud-init** para configurar el escalado de privilegios. En el código para desplegar las imágenes del laboratorio se pueden ver [ejemplos](../terraform/kvm/docker/user_config.cfg):

```yaml
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
  - hostnamectl set-hostname lab-docker.frontend.lab
```

## Creación de inventario

Aunque en la instalación de ansible se crea un inventario global en los ficheros de configuración de ansible y se puede configurar dentro del fichero de configuración de ansible normalmente en **/etc/ansible/ansible.cfg** no se suele utilizar ya que requiere de privilegios de administrador.

Lo habitual es crearnos nuestro propio fichero de inventario:

```ini
[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_user=terraform

[docker]
lab-docker.frontend.lab

[podman]
lab-podman.frontend.lab

[contenedores]
lab-docker.frontend.lab
lab-podman.frontend.lab

[laptop]
localhost ansible_user=jadebustos
```

+ Los corchetes determinan un grupo.
+ **[all:vars]** define las variables para el grupo all que son todas las máquinas en el inventario. Para definir variables para el grupo podman utilizaríamos **[podman:vars]**.
+ **ansible_python_interpreter** indica la versión de python a utilizar en el nodo donde se van a ejecutar las tareas. Es necesario que python se encuentré instalado para poder ejecutar tareas en el con ansible. En algunos equipos aunque se encuentre instalado python 3 si el sistema tiene definido python 2 como interprete por defecto ansible mostrará un warning. De esta forma se utilizará la versión 3 de python aunque la versión por defecto en el sistema sea otra.
+ **ansible_user** indica el usuario con el que se realizará la conexión al equipo donde se quieren realizar las tareas.
+ **localhost ansible_user=jadebustos** establece el usuario que se utilizará para conectarse al equipo localhost.

La ejecución de un playbook sobre todo el inventario definido en el fichero **hosts**:

```console
[jadebustos@ansiblectrl ansible]$ ansible-playbook -i hosts playbook.yaml
```

La ejecución de un playbook sobre el grupo **contenedores** definido en el fichero de inventario **hosts**:

```console
[jadebustos@ansiblectrl ansible]$ ansible-playbook -i hosts -l contenedors playbook.yaml
```

Crearemos un inventario para nuestro entorno con dos máquinas:

```ini
[all:vars]
ansible_python_interpreter=/usr/bin/python3

[controller]
ansiblectrl.jadpb.lab ansible_connection=local

[client]
ansibleclient.jadbp.lab ansible_user=ansible
```

> ![IMPORTANT](../imgs/important-icon.png) Será necesario incluir en tu fichero **/etc/hosts** los FQDN e IPs de ambos nodos para tener resolución o utilizar la dirección IP en lugar del FQDN en el inventario.

## Ejecución de tareas de ansible en los nodos

Para verificar que ansible se ha configurado correctamente desde el controller y usando el usuario que hemos configurado para lanzar las tareas ejecutaremos lo siguiente:

```console
[jadebustos@ansiblectrl ansible]$ cat hosts 
[all:vars]
ansible_python_interpreter=/usr/bin/python3

[controller]
ansiblectrl.jadpb.lab ansible_connection=local

[client]
ansibleclient.jadbp.lab ansible_user=ansible
[jadebustos@ansiblectrl ansible]$ ansible -i hosts -m ping all
ansiblectrl.jadpb.lab | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
ansibleclient.jadbp.lab | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
[jadebustos@ansiblectrl ansible]$ 
```

Para que en un nodo se pueda ejecutar una tarea con ansible será necesario que esté instalado python, de no estar instalado en los clientes donde pretendamos ejecutar tareas con ansible aparecerá un error como este:

```console
[jadebustos@ansiblectrl ansible]$ ansible -i hosts -m ping all
ansibleclient.jadbp.lab | FAILED! => {
    "changed": false,
    "module_stderr": "Shared connection to ansibleclient.jadbp.lab closed.\r\n",
    "module_stdout": "/bin/sh: /usr/bin/python3: No such file or directory\r\n",
    "msg": "The module failed to execute correctly, you probably need to set the interpreter.\nSee stdout/stderr for the exact error",
    "rc": 127
}
ansiblectrl.jadpb.lab | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
[jadebustos@ansiblectrl ansible]$
```

> ![TIP](../imgs/tip-icon.png) Con el comando anterior se ha ejecutado el módulo ping de ansible sobre todos los equipos definidos en el inventario incluido en el fichero **hosts**. Esto nos indica que ansible puede conectarse a los nodos para ejecutar tareas con el usuario indicado por la variable **ansible_user** del fichero de inventario.