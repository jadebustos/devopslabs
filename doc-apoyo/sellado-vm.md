# Sellado de una máquina virtual

Esta operación se hace sobre una VM que se va a utilizar como template y se deberán hacer las siguientes acciones:

+ Borrar las claves ssh:

  ```bash
  [root@localhost ~]# rm -rf /etc/ssh/ssh_host_*
  ```

+ Eliminar las entradas **HWADDRR** y/o **MACADDR** de los ficheros de configuración de interfaces de red.

+ Dejar los ficheros de configuración de las interfaces de red con configuración para DHCP.

+ Asegurarnos de que el hostname es:

  ```bash
  [root@localhost ~]# hostname
  localhost.localdomain
  [root@localhost ~]#
  ```

+ Borrar el machine-id:

  ```bash
  [root@localhost ~]# chmod 777 /etc/machine-id
  [root@localhost ~]# echo > /etc/machine-id
  [root@localhost ~]# rm -rf /var/lib/dbus/machine-id
  [root@localhost ~]#
  ```

+ Apagar la VM y ya se podrá utilizar su disco duro (fichero qcow2) para clonarlo.