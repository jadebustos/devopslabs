
# Tasks that must be done in all nodes prior installation

All nodes must be updated:

<details>
  <summary>CentOS Stream 9</summary>

```console
root@host:~# dnf update -y
```
</details>

<details>
  <summary>Debian 12</summary>

```console
root@host:~# apt update -y ; apt upgrade -y
```
</details>

Time syncronization:

<details>
  <summary>CentOS Stream 9</summary>

```console
root@host:~# timedatectl set-timezone Europe/Madrid
root@host:~# dnf install chrony -y
...
root@host:~# systemctl enable chronyd
root@host:~# systemctl start chronyd
root@host:~# timedatectl set-ntp true
root@host:~#
```
</details>

<details>
  <summary>Debian 12</summary>

```console
root@host:~# timedatectl set-timezone Europe/Madrid
root@host:~# apt install chrony -y
...
root@host:~# systemctl enable chronyd
root@host:~# systemctl start chronyd
root@host:~# timedatectl set-ntp true
root@host:~#
```
</details>

If SELinux is enabled we must disable it:

```console
root@host:~# sed -i s/=enforcing/=disabled/g /etc/selinux/config
```

> ![IMPORTANT](../imgs/important-icon.png) If the kernel was updated or SELinux disabled we must reboot the server.

The following packages must be installed (some of them are not needed but are installed for troubleshooting purpose):

<details>
  <summary>CentOS Stream 9</summary>

```console
root@host:~# dnf install nfs-utils nfs4-acl-tools wget -y
```
</details>

<details>
  <summary>Debian 12</summary>
  
```console
root@host:~# apt install vim strace telnet bind9-dnsutils net-tools firewalld tmux gpg curl apt-transport-https ca-certificates -y
```
</details>


> ![TIP](../imgs/tip-icon.png) Una buena práctica es crear una VM, aplicar estas tareas que se tienen que realizar en todas las máquinas. Dejarla configurada por dhcp y sin configurar el hostname. Una vez terminada la configuración  se hace el [sellado](doc-apoyo/sellado-vm.md) y las máquinas se clonan a partir de este disco. De esta forma estas tareas se hacen solo una vez y no una vez por máquina. Más información [aquí](../doc-apoyo/sellado-vm.md).