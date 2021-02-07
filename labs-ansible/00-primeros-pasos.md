# Primeros pasos con Ansible

## Acceso a los nodos

Para poder acceder a los nodos gestionados por ansible y poder ejecutar tareas será necesario configurar el acceso mediante clave pública.

Para ello desde el controller de ansible, equipo desde el que ejecutaremos ansible, deberemos crear una clave ssh en la cuenta de usuario desde la que ejecutaremos ansible.

Para comprobar si tenemos creadas claves:

```console
[jadebustos@beast ~]$ ls -lh .ssh/*
-rw-------. 1 jadebustos jadebustos 1.9K Oct 14 20:00 .ssh/authorized_keys
-rw-------. 1 jadebustos jadebustos 1.7K Apr 15  2018 .ssh/id_rsa
-rw-r--r--. 1 jadebustos jadebustos  408 Jan 17 10:50 .ssh/id_rsa.pub
-rw-------. 1 jadebustos jadebustos 4.1K Jan 24 16:11 .ssh/known_hosts
[jadebustos@beast ~]$ 
```

Si no tuvieramos ficheros **.pub** (clave pública) y otro con el mismo nombre pero sin la "extensión" **.pub** deberemos generar las claves ejecutando:

```console
[jadebustos@beast ~]$ ssh-keygen -t rsa -b 4096
Generating public/private rsa key pair.
Enter file in which to save the key (/home/jadebustos/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in id_rsa
Your public key has been saved in id_rsa.pub
The key fingerprint is:
SHA256:d6ePc0yE/+ZhkgTgxPqpNn4iEV5vmbUnCUFt0YXPPUc jadebustos@beast.jadbp.lab
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
[jadebustos@beast ~]$
```

> ![IMPORTANT](../imgs/important-icon.png) No poner contraseña a la clave para que ansible se pueda conectar de forma desasistida.

> ![IMPORTANT](../imgs/important-icon.png) Si se cambia el nombre del fichero para las claves **id_rsa** cuando queramos utilizarla deberemos especificar el fichero con el flag **-i nombre_fichero_claves**.

Una vez generada tendremos que copiar la clave pública a los hosts que queramos gestionar y a la cuenta del usuario con el que se conectará ansible. Si queremos ejecutar desde el host **beast** con el usuario **jadebustos** tareas en el host **nodo1** conectándonos con el usuario **ansible** a dicho nodo podemos copiar la clave:

```console
[jadebustos@beast ~]$ ssh-copy-id -i .ssh/id_rsa.pub ansible@nodo1
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

Si queremos ejecutar tareas privilegiadas con ansible necesitaremos escalar privilegios. Para ello será necesario configurar en sudoers que el usuario que va a ejecutar las tareas de ansible pueda escalar privilegios sin autenticación. Si ese usuario fuera el usuario ansible tendríamos que crear el fichero **/etc/sudoers.d/andible** con el siguiente contenido:

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
[jadebustos@beast ansible]$ ansible-playbook -i hosts playbook.yaml
```

La ejecución de un playbook sobre el grupo **contenedores** definido en el fichero de inventario **hosts**:

```console
[jadebustos@beast ansible]$ ansible-playbook -i hosts -l contenedors playbook.yaml
```

## Ejecución de tareas de ansible en los nodos

Para que en un nodo se pueda ejecutar una tarea con ansible será necesario que esté instalado python:

```console
[jadebustos@archimedes ansible]$ ansible -i hosts -m ping all
master.frontend.lab | FAILED! => {
    "changed": false,
    "module_stderr": "Shared connection to master.frontend.lab closed.\r\n",
    "module_stdout": "/bin/sh: /usr/bin/python3: No such file or directory\r\n",
    "msg": "The module failed to execute correctly, you probably need to set the interpreter.\nSee stdout/stderr for the exact error",
    "rc": 127
}
worker01.frontend.lab | FAILED! => {
    "changed": false,
    "module_stderr": "Shared connection to worker01.frontend.lab closed.\r\n",
    "module_stdout": "/bin/sh: /usr/bin/python3: No such file or directory\r\n",
    "msg": "The module failed to execute correctly, you probably need to set the interpreter.\nSee stdout/stderr for the exact error",
    "rc": 127
}
worker02.frontend.lab | FAILED! => {
    "changed": false,
    "module_stderr": "Shared connection to worker02.frontend.lab closed.\r\n",
    "module_stdout": "/bin/sh: /usr/bin/python3: No such file or directory\r\n",
    "msg": "The module failed to execute correctly, you probably need to set the interpreter.\nSee stdout/stderr for the exact error",
    "rc": 127
}
[jadebustos@archimedes ansible]$ 
```

En los nodos **master.frontend.lab**, **worker01.frontend.lab** y **worker02.frontend.lab** no es posible ejecutar tareas con ansible ya que no tienen instalado python, con lo cual será necesario instalar el paquete **python3**:

```console
[root@nodo ~]# dnf install python3 -y
```

Una vez instalado ya será posible ejecutar tareas con ansible en el nodo:

```console
[jadebustos@archimedes ansible]$ ansible -i hosts -m ping all
worker02.frontend.lab | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
master.frontend.lab | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
worker01.frontend.lab | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
[jadebustos@archimedes ansible]$
```

> ![TIP](../imgs/tip-icon.png) Con el comando anterior se ha ejecutado el módulo ping de ansible sobre todos los equipos definidos en el inventario incluido en el fichero **hosts**. Esto nos indica que ansible puede conectarse a los nodos para ejecutar tareas con el usuario indicado por la variable **ansible_user** del fichero de inventario.