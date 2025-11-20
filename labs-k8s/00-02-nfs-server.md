# NFS server installation

We will configure a NFS server to provide storage to the kubernetes cluster.

Install NFS packages and start the NFS service:

<details>
  <summary>CentOS Stream 9</summary>

```console
root@nfs:~# dnf install nfs-utils net-tools -y
...
root@nfs:~# systemctl  enable nfs-server
Created symlink /etc/systemd/system/multi-user.target.wants/nfs-server.service → /usr/lib/systemd/system/nfs-server.service.
root@nfs:~# systemctl start nfs-server
root@nfs:~# 
```
</details>

<details>
  <summary>Debian 12</summary>

TODO
</details>

Lo siguiente será compartir un directorio para exportar por NFS, para ello creamos un directorio:

```console
[root@nfs ~]# mkdir /srv/nfs
[root@nfs ~]#
```

Ahora tendremos que configurar el acceso al share de NFS de tal forma que el fichero **/etc/exports** sea como el que se muestra cambiando las ips por las de nuestros master y workers:

```console
[root@nfs ~]# cat /etc/exports 
# master
/srv/nfs	192.168.1.110(rw,sync) 
# worker01
/srv/nfs	192.168.1.111(rw,sync) 
# worker02
/srv/nfs	192.168.1.112(rw,sync) 
[root@nfs ~]# 
```

> ![TIP](../imgs/tip-icon.png) En este caso el directorio que hemos creado se encontrará en el sistema de ficheros root donde hay 16 GB libres.
>
> ```console
> [root@nfs ~]# df -hP
> Filesystem                  Size  Used Avail Use% Mounted on
> devtmpfs                    1.9G     0  1.9G   0% /dev
> tmpfs                       1.9G     0  1.9G   0% /dev/shm
> tmpfs                       1.9G  8.6M  1.9G   1% /run
> tmpfs                       1.9G     0  1.9G   0% /sys/fs/cgroup
> /dev/mapper/cs-root          17G  1.8G   16G  11% /
> /dev/vda1                  1014M  401M  614M  40% /boot
> tmpfs                       374M     0  374M   0% /run/user/0
> [root@nfs ~]# 
> ```

Releemos el fichero **/etc/exports** para aplicar la nueva configuración:

```console
[root@nfs ~]# exportfs -r
[root@nfs ~]# exportfs -s
/srv/nfs  192.168.1.110(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
/srv/nfs  192.168.1.111(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
/srv/nfs  192.168.1.112(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
[root@nfs ~]# 
```

Por último necesitaremos abrir los puertos del firewall para que el servicio sea accesible:

```console
[root@nfs ~]# firewall-cmd --permanent --add-service=nfs
success
[root@nfs ~]# firewall-cmd --permanent --add-service=rpc-bind
success
[root@nfs ~]# firewall-cmd --permanent --add-service=mountd
success
[root@nfs ~]# firewall-cmd --reload
success
[root@nfs ~]
```

Para verificar que el nodo master y los workers ven el share por nfs podemos ejecutar en cada uno de ellos:

```console
[root@kubemaster ~]# showmount -e 192.168.1.115
Export list for 192.168.1.115:
/srv/nfs 192.168.1.112,192.168.1.111,192.168.1.110
[root@kubemaster ~]# 
```

> ![TIP](../imgs/tip-icon.png) Añadir un disco para datos no es necesario, pero es buena práctica el tener los datos separados del sistema operativo. Si vamos a servir pocos documentos por NFS no sería necesario añadir un disco adicional. Pero en caso contrario se añade un disco adicional, se crea un filesystem y se monta en el directorio que vamos a exportar.
