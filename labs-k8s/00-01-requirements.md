
# Tasks that must be done in all nodes prior installation

All nodes must be updated:

<details>
  <summary>CentOS Stream 9</summary>

```console
[root@host ~]# dnf update -y
```

</details>

<details>
  <summary>Debian 12</summary>

```console
[root@host ~]# apt update -y ; apt upgrade -y
```
</details>

Time syncronization:

```console
[root@host ~]# timedatectl set-timezone Europe/Madrid
[root@host ~]# dnf install chrony -y
...
[root@host ~]# systemctl enable chronyd
[root@host ~]# systemctl start chronyd
[root@host ~]# timedatectl set-ntp true
[root@host ~]#
```

Si SELinux estuviera activado lo desativamos ya que no lo vamos a utilizar con kubernetes:

```console
[root@host ~]# sed -i s/=enforcing/=disabled/g /etc/selinux/config
```

Instalamos los siguientes paquetes:

```console
[root@host ~]# dnf install nfs-utils nfs4-acl-tools wget -y
```

> ![IMPORTANT](../imgs/important-icon.png) Si se ha actualizado el kernel o ha sido necesario desactivar SELinux será necesario reiniciar.

> ![TIP](../imgs/tip-icon.png) Una buena práctica es crear una VM, aplicar estas tareas que se tienen que realizar en todas las máquinas. Dejarla configurada por dhcp y sin configurar el hostname. Una vez terminada la configuración  se hace el [sellado](doc-apoyo/sellado-vm.md) y las máquinas se clonan a partir de este disco. De esta forma estas tareas se hacen solo una vez y no una vez por máquina. Más información [aquí](../doc-apoyo/sellado-vm.md).