# Instalación laboratorio

Se desplegaran varias máquinas virtuales, todas ellas en la misma red.

Para realizar estos laboratorios tenemos dos opciones.

## Opción uno

Tener una máquina linux con kvm, [terraform](https://www.terraform.io/downloads.html) y ansible instalados:

+ Instala el [provider de Terraform para kvm](01-terraform-kvm-provider.md).
+ Crea una máquina virtual con [Centos 8 o Centos 8 Stream](https://www.centos.org/download/).
+ Dejala configurada para dhcp y no configures el hostname.
+ Haz una instalación mínima, asegurate de que el paquete **python36** se encuentra instalado y después instala [cloud-init](../doc-apoyo/cloud-init.md).
+ Una vez instalada actualiza todos los paquetes:

  ```console
  [root@localhost ssh]# dnf update -y
  ``` 
+ Copia una clave ssh al usuario root para poder acceder con ansible mas tarde.
+ Puedes ejecutar un proceso de seal a la máquina o bien haz los siguientes pasos que serían suficientes para el propósito del lab:
  + Antes de parar edita el fichero **/etc/machine-id** y borra la línea que aparece.
  + Borra las claves de SSH:

    ```console
    [root@localhost ssh]# cd /etc/ssh/

    [root@localhost ssh]# rm -f *key*
    [root@localhost ssh]#
    ```
+ Apaga la máquina virtual y cuando esté apagada haz una copia del disco. Esta copia se utilizará para clonar las vms para los labs:

  ```console
  [root@kvm ~]# cd /var/lib/libvirt/images/
  [root@kvm images]# qemu-img convert -f qcow2 -O qcow2 centos8.qcow2 centos8-template.qcow2
  ```

  + **/var/lib/libvirt/images/** es la ruta por defecto que utiliza kvm para almacnar los discos de las vms. Si lo has instalado en otra ruta debes cambiarla por la adecuada.
  + **centos8.qcow2** es el disco de la máquina centos que hemos creado.
  + **centos8-template.qcow2** es el disco que utilizará Terraform para crear las máquinas del laboratorio.

+ Clona el [repositorio devopslabs](https://github.com/jadebustos/devopslabs) en la maquina con kvm:

  ```console
  [user@kvm ~]$ git clone https://github.com/jadebustos/devopslabs
  ```

+ Dentro del código Terraform en los ficheros **vars.tf**: 

  + Modifica el valor default para que coincida con la ruta del template que has creado:
  
    ```
    variable "qcow2_image" {
      type = string
      description = "imagen qcow2 para desplegar"
      default = "/var/lib/libvirt/images/centos8-template.qcow2"
    }
    ```

  + Asegurate que en el filesystem tiene espacio suficiente o si quieres cambiarlo a otra ruta puedes hacerlo. El valor especificado en **default** no debe existir ya que lo creará:

    ```
    variable "pool_path" {
      type = string
      description = "directorio donde se almacenara el qcow2"
      default = "/var/lib/libvirt/images/terraform/docker"
    }
    ```
  + Cambia el valor de **default** a una red que exista en tu entorno kvm:

      ```
      variable "network_name" {
        type = string
        description = "red para la maquina virtual"
        default = "frontend"
      }
      ```
+ Cambia la configuración de red de **cloud-init** para que coincida con la de la red en la que vas a desplegar. Se encuentra en los ficheros **network_config.cfg**:

  ```yaml
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
      search: [ 'frontend.lab' ]
  ```
+ En el directorio donde se encuentra el plan de terraform ahora podrás desplegar la vm:

  ```console
  [user@kvm docker]$ terraform init
  ..
  [user@kvm docker]$ terraform apply
  ..
  [user@kvm docker]$ cd ../podman
  [user@kvm podman]$ terraform init
  ...
  [user@kvm podman]$ terraform apply
  ...
  [user@kvm podman]$
  ```

## Opción dos

Crea dos máquinas virtuales con el software de virtualización que utilices, **vmware**, **virtual**, ...

+ Haz una instalación mínima, asegurate de que el paquete **python36** y se encuentra instalado.
+ Una vez instalada actualiza todos los paquetes:

  ```console
  [root@localhost ssh]# dnf update -y
  ``` 
+ Copia una clave ssh al usuario root para poder acceder con ansible mas tarde.
+ Instala **ansible** en la máquina que ejecuta las máquinas virtuales o crea una tercera máquina e instalale ansible.
+ En el nodo donde se encuentre ansible necesitarás crear una clave ssh, para Linux:

  ```console
  [user@ansible ~]$ ssh-keygen -t rsa -b 4096
  ```

  Acepta los valores por defecto. El fichero de clave publica que se encontrará en el directorio **.ssh/id_rsa.pub** será el que tendrás que copiar las máquinas que has creado:

  ```console
  [user@ansible ~]$ ssh-copy-id -i .ssh/id_rsa.pub root@maquina-docker
  root@maquina-docker's password:
  [user@ansible ~]$ ssh-copy-id -i .ssh/id_rsa.pub root@maquina-podman
  root@maquina-docker's password:
  [user@ansible ~]$
  ```

  ## Configuración de las máquinas

  Una vez que esten creadas independientemente de si se han desplegado con terraform o no para configurarlas:

  + En el directorio ansible tendrás que modificar el inventario para que tenga el fqdn de la máquina (si tienes resolución DNS) o la dirección IP que le hayas configurado:

    ```
    [all:vars]
    ansible_python_interpreter=/usr/bin/python3
    ansible_user=terraform

    [docker]
    lab-docker.frontend.lab

    [podman]
    lab-podman.frontend.lab
    ```

  + Utiliza los playbooks de ansible para configurarlas:

    ```console
    [user@ansible ansible]$ ansible-playbook -i hosts -l docker install-docker.yaml
    ...
    [user@ansible ansible]$ ansible-playbook -i hosts -l podman install-podman.yaml
    ...
    [user@ansible ansible]$
    ```