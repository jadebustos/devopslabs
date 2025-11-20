
# Requirements

The following tasks must be done in all nodes prior installation.

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
AÑADIR EL RESTO DE PAQUETES QUE SE INSTALAN EN DEBIAN
</details>

<details>
  <summary>Debian 12</summary>

```console
root@host:~# apt install vim strace telnet bind9-dnsutils net-tools firewalld tmux gpg curl apt-transport-https ca-certificates -y
```
FALTA INSTALAR LAS UTILIZADES NFS
</details>

> ![TIP](../imgs/tip-icon.png) A recommendation is create one VM, perform all these tasks, configure it with dhcp and with no hostname configuration. Once finished configuration you can [seal the vm](supporting-doc/sealing-vm.md) and after that you can clone the other VMs, configure the network and the hostname. So you will perform these tasks only once.