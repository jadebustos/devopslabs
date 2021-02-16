# Instalando Kubernetes

## Creación de las máquinas virtuales

Crear las siguientes máquinas virtuales con una interface de red sobre la misma red todas ellas.

-----------------------------------------------------------------
| Role | Sistema Operativo | vCPUs | Memoria (GiB) | Disco Duro |
|------|-------------------|-------|---------------|------------|
| NFS  | CentOS 8          | 2     | 4             | 1 x 20 GiB (boot), 1 x 10 GiB (data) |
| Master | CentOS 8        | 2     | 8             | 1 x 20 GiB (boot) |
| Worker | CentOS 8        | 2     | 4             | 1 x 20 GiB (boot) |
| Worker | CentOS 8        | 2     | 4             | 1 x 20 GiB (boot) |

Suponiendo que la red en la que vamos a desplegarlas es la **192.168.1.0/24** configuramos las máquinas con direccionamiento estático:

---------------
| Nombre | IP |
|------|------|
| nfs.acme.es  | 192.168.1.115/24 |
| master.acme.es | 192.168.1.110/24 | 
| worker01.acme.es | 192.168.1.111/24 | 
| worker02.acme.es | 192.168.1.112/24 | 

El fichero de configuración del interface de red **/etc/sysconfig/network-script/ifcfg-enp1s0**:

```
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=no
IPV6_AUTOCONF=no
IPV6_DEFROUTE=no
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=enp1s0
UUID=7ff72f73-5b87-4685-8dd2-c92fed809bcb
DEVICE=enp1s0
ONBOOT=yes
IPADDR=192.168.1.115
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
DNS1=192.168.1.200
DOMAIN=acme.es
```

> ![WARNING](../imgs/warning-icon.png) El nombre del interface de red puede cambiar.

Una vez arrancadas las máquinas, nos aseguramos que estan actualizadas a último nivel ejecutando en cada una de ellas:

```console
[root@host ~]# dnf update -y
```

## Tareas previas de configuración

Estas tareas se tendrán que realizar en todas las VMs del laboratorio:

Tendremos que configurar la sincronización horaria:

```console
[root@host ~]# timedatectl set-timezone Europe/Madrid
[root@host ~]# dnf install chrony -y
...
[root@host ~]# systemctl enable chronyd
[root@host ~]# systemctl start chronyd
[root@host ~]# timedatectl set-ntp true
[root@host ~]#
```

Desactivamos SELinux ya que no lo vamos a utilizar con kubernetes:

```console
[root@host ~]# sed -i s/=enforcing/=disabled/g /etc/selinux/config
```

Instalamos los siguientes paquetes:

```console
[root@host ~]# dnf install nfs-utils nfs4-acl-tools wget -y
```

> ![TIP](../imgs/tip-icon.png) Una buena práctica es crear una VMs aplicar estas tareas que se tienen que realizar en todas las máquinas. Dejarla configurada por dhcp y sin configurar el hostname. Una vez terminada la configuración  se hace el [sellado](doc-apoyo/sellado-vm.md) y las máquinas se clonan a partir de este disco. De esta forma estas tareas se hacen solo una vez y no una vez por máquina. Más información [aquí](../doc-apoyo/sellado-vm.md).

## Instalación del servidor NFS

Este servidor lo utilizaremos para ofrecer almacenamiento al cluster de kubernetes.

Lo primero que haremos será configurar el NFS, para ello identificaremos el disco de datos en el sistema:

```console
[root@nfs ~]# lsblk
NAME        MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
vda         252:0    0  20G  0 disk 
├─vda1      252:1    0   1G  0 part /boot
└─vda2      252:2    0  19G  0 part 
  ├─cs-root 253:0    0  17G  0 lvm  /
  └─cs-swap 253:1    0   2G  0 lvm  [SWAP]
vdb         252:16   0  10G  0 disk 
[root@nfs ~]# 
```

El disco para datos es **/dev/vdb**.

Vamos a crear un VG (volume group) y LV (logical volume) ya que si en un futuro es necesario ampliar el espacio lo podremos hacer de una forma rápida, fácil y transparente:

```console
[root@nfs ~]# pvcreate /dev/vdb
  Physical volume "/dev/vdb" successfully created.
[root@nfs ~]# vgcreate data_vg /dev/vdb
  Volume group "data_vg" successfully created
[root@nfs ~]# vgdisplay data_vg
  --- Volume group ---
  VG Name               data_vg
  System ID             
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  1
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                0
  Open LV               0
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <10.00 GiB
  PE Size               4.00 MiB
  Total PE              2559
  Alloc PE / Size       0 / 0   
  Free  PE / Size       2559 / <10.00 GiB
  VG UUID               8P6gNC-n3cC-9px1-Lq1P-CV5c-JRiF-rwrKfs

   
[root@nfs ~]# lvcreate -l+2559 -n nfs_lv /dev/data_vg
  Logical volume "nfs_lv" created.
[root@nfs ~]# lvs
  LV     VG      Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  root   cs      -wi-ao---- <17.00g                                                    
  swap   cs      -wi-ao----   2.00g                                                    
  nfs_lv data_vg -wi-a----- <10.00g                                                    
[root@nfs ~]# 
```

Ahora que tenemos creado el logical volume vamos a crear el filesystem de tipo XFS:

```console
[root@nfs ~]# mkfs.xfs /dev/data_vg/nfs_lv 
meta-data=/dev/data_vg/nfs_lv    isize=512    agcount=4, agsize=655104 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=0
         =                       reflink=1
data     =                       bsize=4096   blocks=2620416, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
Discarding blocks...Done.
[root@nfs ~]# 
```

Ahora crearemos el punto de montaje e incluiremos a este logical volume en **/etc/fstab** para que se monte en los inicios de la VM:

```console
[root@nfs ~]# mkdir /srv/nfs
[root@nfs ~]# echo "/dev/data_vg/nfs_lv        /srv/nfs                xfs     defaults        0 0" >> /etc/fstab
[root@nfs ~]# 
```

Para comprobar que la configuración de monaje del sistema de ficheros es correcta si ejecutamos **mount -a** deberemos ver el sistema de ficheros montado:

```console
[root@nfs ~]# mount -a
[root@nfs ~]# df -hP
Filesystem                  Size  Used Avail Use% Mounted on
devtmpfs                    1.9G     0  1.9G   0% /dev
tmpfs                       1.9G     0  1.9G   0% /dev/shm
tmpfs                       1.9G  8.6M  1.9G   1% /run
tmpfs                       1.9G     0  1.9G   0% /sys/fs/cgroup
/dev/mapper/cs-root          17G  1.8G   16G  11% /
/dev/vda1                  1014M  401M  614M  40% /boot
tmpfs                       374M     0  374M   0% /run/user/0
/dev/mapper/data_vg-nfs_lv   10G  104M  9.9G   2% /srv/nfs
[root@nfs ~]# 
```

Instalamos los paquetes de NFS y arrancamos el servicio:

```console
[root@nfs ~]# dnf install nfs-utils net-tools -y
...
[root@nfs ~]# systemctl  enable nfs-server
Created symlink /etc/systemd/system/multi-user.target.wants/nfs-server.service → /usr/lib/systemd/system/nfs-server.service.
[root@nfs ~]# systemctl start nfs-server
[root@nfs ~]# 
```

Ahora tendremos que configurar el acceso al share de NFS de tal forma que el fichero **/etc/exports** sea como el que se muestra cambiando las ips por las de nuestros master y workers:

```console
[root@nfs ~]# cat /etc/exports 
/srv/nfs	192.168.1.110(rw,sync)
/srv/nfs	192.168.1.111(rw,sync)
/srv/nfs	192.168.1.112(rw,sync)
[root@nfs ~]# 
```

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
[root@master ~]# showmount -e 192.168.1.115
Export list for 192.168.1.115:
/srv/nfs 192.168.1.112,192.168.1.111,192.168.1.110
[root@master ~]# 
```

## Tareas comunes a realizar en el nodo master y los workers

Configura resolución DNS si dispones de un servidor DNS. Si no dispones de uno siempre puedes incluir en el fichero **/etc/hosts** las siguientes líneas:

```
192.168.1.110 master master.acme.es
192.168.1.111 worker01 worker01.acme.es
192.168.1.112 worker02 worker02.acme.es5
192.168.1.115 nfs nfs.acme.es
```

Vamos a activar **transparent masquerading** para que los PODs puedan comunicarse dentro del cluster mediante VXLAN:

```console
[root@host ~]# modprobe br_netfilter
[root@host ~]# firewall-cmd --add-masquerade --permanent
success
[root@host ~]# firewall-cmd --reload
success
[root@host ~]# 
```

> ![INFORMATION](../imgs/information-icon.png) Los Pods se ejecutan dentro de su propia red aislados de la red en la que se encuentran las máquinas, pero es necesario que se puedan comunicar entre ellos. Para ello kubernetes utiliza un protocolo de llamado [VXLAN](https://en.wikipedia.org/wiki/Virtual_Extensible_LAN).

> ![INFORMATION](../imgs/information-icon.png) Existen otros protocolos para el mismo propósito como son [GRE](https://en.wikipedia.org/wiki/Generic_Routing_Encapsulation) y [Geneve](https://en.wikipedia.org/wiki/Generic_Networking_Virtualization_Encapsulation) que son utilizados por otras tecnologías cloud como Openstack además de utilizar VXLAN también.

Para permitir que kubernetes maneje correctamente el tráfico con el cortafuegos:

```console
[root@host ~]# cat <<EOF > /etc/sysctl.d/k8s.conf
> net.bridge.bridge-nf-call-ip6tables = 1
> net.bridge.bridge-nf-call-iptables = 1
> EOF
[root@host ~]# sysctl --system
...
* Applying /etc/sysctl.d/k8s.conf ...
...
[root@host ~]# 
```

Si tenemos activado el swap:

```console
[root@host ~]# free -m
              total        used        free      shared  buff/cache   available
Mem:           7768         168        7407           8         191        7362
Swap:          2047           0        2047
[root@host ~]#
```

Para desactivarla:

```console
[root@host ~]# swapoff  -a
[root@host ~]# free -m
              total        used        free      shared  buff/cache   available
Mem:           7768         167        7409           8         190        7363
Swap:             0           0           0
[root@host ~]# 
```

Ahora es necesario también eliminar la línea del fichero **/etc/fstab** que monta en el arranque el swap:

```console
[root@host ~]# cat /etc/fstab 

#
# /etc/fstab
# Created by anaconda on Sun Oct  4 18:06:49 2020
#
# Accessible filesystems, by reference, are maintained under '/dev/disk/'.
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info.
#
# After editing this file, run 'systemctl daemon-reload' to update systemd
# units generated from this file.
#
/dev/mapper/cs-root     /                       xfs     defaults        0 0
UUID=35d72d21-6f35-4e52-ac4d-523a28ac5b5d /boot                   xfs     defaults        0 0
/dev/mapper/cs-swap     none                    swap    defaults        0 0
# sed -i '/swap/d' /etc/fstab
# cat /etc/fstab 

#
# /etc/fstab
# Created by anaconda on Sun Oct  4 18:06:49 2020
#
# Accessible filesystems, by reference, are maintained under '/dev/disk/'.
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info.
#
# After editing this file, run 'systemctl daemon-reload' to update systemd
# units generated from this file.
#
/dev/mapper/cs-root     /                       xfs     defaults        0 0
UUID=35d72d21-6f35-4e52-ac4d-523a28ac5b5d /boot                   xfs     defaults        0 0
[root@host ~]# 
```

> ![IMPORTANT](../imgs/important-icon.png) Se desactiva para no perder rendimiento al hacer swap, ademas en el espacio de swap se puede volcar información de diferentes entornos que deberían estar aislados y se perdería el aislamiento. [Más información](https://github.com/kubernetes/kubernetes/issues/53533)

Instalamos docker que será el engine para ejecutar contenedores:

```console
[root@host ~]# dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
Adding repo from: https://download.docker.com/linux/centos/docker-ce.repo
[root@host ~]# dnf install docker-ce-19.03.14-3.el8 containerd.io -y
...
[root@host ~]# systemctl enable docker
Created symlink /etc/systemd/system/multi-user.target.wants/docker.service → /usr/lib/systemd/system/docker.service.
[root@host ~]# systemctl start docker
[root@host ~]#
```

> ![INFORMATION](../imgs/information-icon.png) Instalamos la version **19.03** de docker por que es la última testeada en kubernetes.

Configuramos el repositorio de kubernetes:

```console
[root@host ~]# cat <<EOF > /etc/yum.repos.d/kubernetes.repo
> [kubernetes]
> name=Kubernetes
> baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
> enabled=1
> gpgcheck=1
> repo_gpgcheck=1
> gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
> exclude=kubelet kubeadm kubectl
> EOF
[root@host ~]#
```

Instalamos kubernetes:

```console
[root@host ~]# dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
...
[root@host ~]# systemctl enable kubelet
Created symlink /etc/systemd/system/multi-user.target.wants/kubelet.service → /usr/lib/systemd/system/kubelet.service.
[root@host ~]# systemctl start kubelet
[root@host ~]#
```

## Configurando kubernetes en el nodo master

Configuramos el firewall para acceder a los servicios de kubernetes:

```console
[root@master ~]# firewall-cmd --permanent --add-port=6443/tcp
success
[root@master ~]# firewall-cmd --permanent --add-port=2379-2380/tcp
success
[root@master ~]# firewall-cmd --permanent --add-port=10250/tcp
success
[root@master ~]# firewall-cmd --permanent --add-port=10251/tcp
success
[root@master ~]# firewall-cmd --permanent --add-port=10252/tcp
success
[root@master ~]# firewall-cmd --permanent --add-port=10255/tcp
success
[root@master ~]# firewall-cmd --reload
success
[root@master ~]# 
```

| Protocol | Direction | Port Range | Purpose | Used by |
|----------|-----------|------------|---------|---------|
| TCP | Inbound  | 6443 | Kubernetes API Server | All |
| TCP | Inbound  | 2379-2380 | etcd server client API | kube-apiserver, etcd |
| TCP | Inbound  | 10250 | Kubelet API | self, Control Plane |
| TCP | Inbound  | 10251 | kube-scheduler | self |
| TCP | Inbound  | 10252 | kube-controller-manager| self |
| TCP | Inbound  | 10255 | Statistics | Master nodes |

> ![INFORMATION](../imgs/information-icon.png) El puerto 10255 se utiliza para recoger estadísticas y solo debería ser poder accedido por los masters.

Configuramos **kudeadm**:

```console
[root@master ~]# kubeadm config images pull
[config/images] Pulled k8s.gcr.io/kube-apiserver:v1.20.2
[config/images] Pulled k8s.gcr.io/kube-controller-manager:v1.20.2
[config/images] Pulled k8s.gcr.io/kube-scheduler:v1.20.2
[config/images] Pulled k8s.gcr.io/kube-proxy:v1.20.2
[config/images] Pulled k8s.gcr.io/pause:3.2
[config/images] Pulled k8s.gcr.io/etcd:3.4.13-0
[config/images] Pulled k8s.gcr.io/coredns:1.7.0
[root@master ~]# 
```
Permitiremos el acceso desde los workers:

```console
[root@master ~]# firewall-cmd --permanent --add-rich-rule 'rule family=ipv4 source address=192.168.1.111/32 accept'
success
[root@master ~]# firewall-cmd --permanent --add-rich-rule 'rule family=ipv4 source address=192.168.1.112/32 accept'
success
[root@master ~]# firewall-cmd --reload
success
[root@master ~]
```

> ![IMPORTANT](../imgs/important-icon.png) Esto no es una buena práctica. En un entorno en producción deberíamos permitir únicamente el tráfico necesario y no todo el tráfico entre el master y los workers.

Permitimos el acceso de los contenedores a localhost:

```console
[root@master ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:77:3a:3a brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.110/24 brd 192.168.1.255 scope global noprefixroute enp1s0
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe77:3a3a/64 scope link 
       valid_lft forever preferred_lft forever
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:58:7f:3f:fc brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
[root@master ~]# firewall-cmd --zone=public --permanent --add-rich-rule 'rule family=ipv4 source address=172.17.0.0/16 accept'
success
[root@master ~]# firewall-cmd --reload
success
[root@master ~]#
```

Instalamos el plugin CNI (Container Network Interface) de kubernetes y definimos la red de los PODs:

```console
[root@master ~]# kubeadm init --pod-network-cidr 192.169.0.0/16
[init] Using Kubernetes version: v1.20.2
[preflight] Running pre-flight checks
...
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.1.110:6443 --token gmk4le.8gsfpknu99k78qut \
    --discovery-token-ca-cert-hash sha256:d2cd35c9ab95f4061aa9d9b993f7e8742b2307516a3632b27ea10b64baf8cd71 
[root@master ~]# 
```

> ![IMPORTANT](../imgs/important-icon.png) Guarda el comando kubeadm ya que lo necesitarás para unir los workers al clúster.

> ![TIP](../imgs/tip-icon.png) Si automatizas el despliegue de kubernetes con ansible necesitarás guardar la salida del último comando para poder añadir workers al cluster. Como en la ejecución de ansible no se ve la salida del comando podemos almacenar la salida del comando en una variable y mostrarla. En [01-playbooks.md](../labs-ansible/01-playbooks.md) se puede ver un ejemplo de un playbook que almacena la salida de un comando en una variable y luego se imprime en la salida estándar el valor de dicha variable.

Es muy importante que la red que utilicemos para los PODs tenga IPs suficientes para el número de contenedores que queramos arrancar y no debe tener solapamiento con las redes ya existentes.

En este caso la red que hemos configurado para los pods es de Clase C con una cantidad total de IPs de **65.536**.

> ![TIP](../imgs/tip-icon.png) [Installing a POD network](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network)

Vamos a autorizar al usuario **root** acceder al cluster para terminar la configuración:

```console
[root@master ~]# mkdir -p /root/.kube
[root@master ~]# cp -i /etc/kubernetes/admin.conf /root/.kube/config
[root@master ~]# chown $(id -u):$(id -g) /root/.kube/config
[root@master ~]# kubectl get nodes
NAME             STATUS     ROLES                  AGE     VERSION
master.acme.es   NotReady   control-plane,master   9m49s   v1.20.2
[root@master ~]# 
```

Vemos que se muestra como **NotReady**. Eso es debido a que no hemos desplegado la red para los PODs todavía.

## Instalando la SDN

Como SDN vamos a instalar [Calico](https://docs.projectcalico.org/).

Instalamos el operador de Tigera:

```console
[root@master ~]# kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgppeers.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/blockaffinities.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/clusterinformations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworksets.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/hostendpoints.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamblocks.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamconfigs.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamhandles.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/kubecontrollersconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networksets.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/installations.operator.tigera.io created
customresourcedefinition.apiextensions.k8s.io/tigerastatuses.operator.tigera.io created
namespace/tigera-operator created
podsecuritypolicy.policy/tigera-operator created
serviceaccount/tigera-operator created
clusterrole.rbac.authorization.k8s.io/tigera-operator created
clusterrolebinding.rbac.authorization.k8s.io/tigera-operator created
deployment.apps/tigera-operator created
[root@master ~]#
```

Instalamos Calico junto con los custom resources que necesita. Para ello descargamos primero el fichero de definición:

```console
[root@master ~]# wget https://docs.projectcalico.org/manifests/custom-resources.yaml
[root@master ~]#
```

Y cambiamos el **cidr** para que coincida con el de nuestra red de PODs, el fichero [custom-resources.yaml](https://docs.projectcalico.org/manifests/custom-resources.yaml):

```yaml
# This section includes base Calico installation configuration.
# For more information, see: https://docs.projectcalico.org/v3.17/reference/installation/api#operator.tigera.io/v1.Installation
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Configures Calico networking.
  calicoNetwork:
    # Note: The ipPools section cannot be modified post-install.
    ipPools:
    - blockSize: 26
      cidr: 192.169.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
```

Instalamos Calico:

```console
[root@master ~]# kubectl apply -f custom-resources.yaml
installation.operator.tigera.io/default created
[root@master ~]# 
```
Después de unos minutos veremos el clúster como **Ready**:

```console
[root@master ~]# kubectl get nodes
NAME             STATUS   ROLES                  AGE   VERSION
master.acme.es   Ready    control-plane,master   18m   v1.20.2
[root@master ~]# kubectl get pods -A
NAMESPACE         NAME                                       READY   STATUS    RESTARTS   AGE
calico-system     calico-kube-controllers-546d44f5b7-szm8j   1/1     Running   0          8m3s
calico-system     calico-node-dltbq                          1/1     Running   0          8m3s
calico-system     calico-typha-5698b66ddc-5dbxs              1/1     Running   0          8m5s
kube-system       coredns-74ff55c5b-5cp24                    1/1     Running   0          21m
kube-system       coredns-74ff55c5b-w68pg                    1/1     Running   0          21m
kube-system       etcd-master.acme.es                        1/1     Running   1          21m
kube-system       kube-apiserver-master.acme.es              1/1     Running   1          21m
kube-system       kube-controller-manager-master.acme.es     1/1     Running   1          21m
kube-system       kube-proxy-fftw7                           1/1     Running   1          21m
kube-system       kube-scheduler-master.acme.es              1/1     Running   1          21m
tigera-operator   tigera-operator-657cc89589-wqgd6           1/1     Running   0          11m
[root@master ~]# 
```

Aunque hemos utilizado [Calico](https://docs.projectcalico.org/getting-started/kubernetes/) como [SDN](https://en.wikipedia.org/wiki/Software-defined_networking) podemos utilizar otras SDNs. Mas información en [Kubernetes Networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/).

Podemos ver la configuración del master de red:

```console
[root@master ~]# ip a 
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:77:3a:3a brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.110/24 brd 192.168.1.255 scope global noprefixroute enp1s0
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe77:3a3a/64 scope link 
       valid_lft forever preferred_lft forever
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:a5:5e:1e:9d brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
6: vxlan.calico: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default 
    link/ether 66:00:50:49:a7:f6 brd ff:ff:ff:ff:ff:ff
    inet 192.169.121.64/32 scope global vxlan.calico
       valid_lft forever preferred_lft forever
    inet6 fe80::6400:50ff:fe49:a7f6/64 scope link 
       valid_lft forever preferred_lft forever
7: calie0e54e1fe93@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default 
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::ecee:eeff:feee:eeee/64 scope link 
       valid_lft forever preferred_lft forever
8: cali16a4c4a3288@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default 
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netnsid 1
    inet6 fe80::ecee:eeff:feee:eeee/64 scope link 
       valid_lft forever preferred_lft forever
9: cali793ff21fd58@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default 
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netnsid 2
    inet6 fe80::ecee:eeff:feee:eeee/64 scope link 
       valid_lft forever preferred_lft forever
[root@master ~]# 
```

> ![INFORMATION](../imgs/information-icon.png) [Calico Quickstart](https://docs.projectcalico.org/getting-started/kubernetes/quickstart)

> ![INFORMATION](../imgs/information-icon.png) [Calico Requirements](https://docs.projectcalico.org/getting-started/kubernetes/requirements)

## Configurando los workers

Lo primero que tenemos que hacer en los workers es abrir los puertos:

```console
[root@worker0X ~]# firewall-cmd --zone=public --permanent --add-port={10250,30000-32767}/tcp
success
[root@worker0X ~]# firewall-cmd --reload
success
[root@worker0X ~]#
```

Ahora para unirse al clúster tendremos que ejecutar en los nodos el comando de **kubeadm** que nos produjo la ejecución de **kubadmin init**:

```console
[root@worker0X ~]# kubeadm join 192.168.1.110:6443 --token gmk4le.8gsfpknu99k78qut --discovery-token-ca-cert-hash sha256:d2cd35c9ab95f4061aa9d9b993f7e8742b2307516a3632b27ea10b64baf8cd71 
...

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

[root@worker0X ~]# 
```

Puede llevar unos minutos que los workers aparezcan como **Ready**:

```console
[root@master ~]# kubectl get nodes
NAME               STATUS   ROLES                  AGE   VERSION
master.acme.es     Ready    control-plane,master   36m   v1.20.2
worker01.acme.es   Ready    <none>                 12m   v1.20.2
worker02.acme.es   Ready    <none>                 12m   v1.20.2
[root@master ~]# kubectl get pods -A -o wide
NAMESPACE         NAME                                       READY   STATUS    RESTARTS   AGE   IP               NODE               NOMINATED NODE   READINESS GATES
calico-system     calico-kube-controllers-546d44f5b7-szm8j   1/1     Running   0          31m   192.169.121.67   master.acme.es     <none>           <none>
calico-system     calico-node-dltbq                          1/1     Running   0          31m   192.168.1.110    master.acme.es     <none>           <none>
calico-system     calico-node-h86k4                          1/1     Running   0          21m   192.168.1.112    worker02.acme.es   <none>           <none>
calico-system     calico-node-xkxgw                          1/1     Running   0          21m   192.168.1.111    worker01.acme.es   <none>           <none>
calico-system     calico-typha-5698b66ddc-5dbxs              1/1     Running   0          31m   192.168.1.110    master.acme.es     <none>           <none>
calico-system     calico-typha-5698b66ddc-6nzxw              1/1     Running   0          20m   192.168.1.111    worker01.acme.es   <none>           <none>
calico-system     calico-typha-5698b66ddc-lsj8t              1/1     Running   0          20m   192.168.1.112    worker02.acme.es   <none>           <none>
kube-system       coredns-74ff55c5b-5cp24                    1/1     Running   0          45m   192.169.121.65   master.acme.es     <none>           <none>
kube-system       coredns-74ff55c5b-w68pg                    1/1     Running   0          45m   192.169.121.66   master.acme.es     <none>           <none>
kube-system       etcd-master.acme.es                        1/1     Running   1          45m   192.168.1.110    master.acme.es     <none>           <none>
kube-system       kube-apiserver-master.acme.es              1/1     Running   1          45m   192.168.1.110    master.acme.es     <none>           <none>
kube-system       kube-controller-manager-master.acme.es     1/1     Running   1          45m   192.168.1.110    master.acme.es     <none>           <none>
kube-system       kube-proxy-bm6fs                           1/1     Running   0          21m   192.168.1.112    worker02.acme.es   <none>           <none>
kube-system       kube-proxy-cd2xq                           1/1     Running   0          21m   192.168.1.111    worker01.acme.es   <none>           <none>
kube-system       kube-proxy-fftw7                           1/1     Running   1          45m   192.168.1.110    master.acme.es     <none>           <none>
kube-system       kube-scheduler-master.acme.es              1/1     Running   1          45m   192.168.1.110    master.acme.es     <none>           <none>
tigera-operator   tigera-operator-657cc89589-wqgd6           1/1     Running   0          35m   192.168.1.110    master.acme.es     <none>           <none>
[root@master ~]# 
```

En los workers:

```console
[root@worker01 ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:4d:c6:3d brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.111/24 brd 192.168.1.255 scope global noprefixroute enp1s0
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe4d:c63d/64 scope link 
       valid_lft forever preferred_lft forever
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:e8:69:bb:59 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
6: vxlan.calico: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default 
    link/ether 66:77:c0:0a:f4:39 brd ff:ff:ff:ff:ff:ff
    inet 192.169.112.0/32 scope global vxlan.calico
       valid_lft forever preferred_lft forever
    inet6 fe80::6477:c0ff:fe0a:f439/64 scope link 
       valid_lft forever preferred_lft forever
[root@worker01 ~]# 
```

```console
[root@worker02 ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:93:56:54 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.112/24 brd 192.168.1.255 scope global noprefixroute enp1s0
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe93:5654/64 scope link 
       valid_lft forever preferred_lft forever
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:bb:47:0c:32 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
6: vxlan.calico: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default 
    link/ether 66:79:e1:85:f5:20 brd ff:ff:ff:ff:ff:ff
    inet 192.169.22.0/32 scope global vxlan.calico
       valid_lft forever preferred_lft forever
    inet6 fe80::6479:e1ff:fe85:f520/64 scope link 
       valid_lft forever preferred_lft forever
[root@worker02 ~]# ping -c 4 192.169.112.0
PING 192.169.112.0 (192.169.112.0) 56(84) bytes of data.
64 bytes from 192.169.112.0: icmp_seq=1 ttl=64 time=4.67 ms
64 bytes from 192.169.112.0: icmp_seq=2 ttl=64 time=0.464 ms
64 bytes from 192.169.112.0: icmp_seq=3 ttl=64 time=0.598 ms
64 bytes from 192.169.112.0: icmp_seq=4 ttl=64 time=0.774 ms

--- 192.169.112.0 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3042ms
rtt min/avg/max/mdev = 0.464/1.625/4.665/1.758 ms
[root@worker02 ~]# 
```

## Desplegando un ingress controller

Para poder acceder a los PODs desde fuera de kubernetes necesitaremos instalar un ingress controller:

```console
[root@master ~]# kubectl apply -f https://raw.githubusercontent.com/haproxytech/kubernetes-ingress/v1.5/deploy/haproxy-ingress.yaml
namespace/haproxy-controller created
serviceaccount/haproxy-ingress-service-account created
clusterrole.rbac.authorization.k8s.io/haproxy-ingress-cluster-role created
clusterrolebinding.rbac.authorization.k8s.io/haproxy-ingress-cluster-role-binding created
configmap/haproxy created
deployment.apps/ingress-default-backend created
service/ingress-default-backend created
deployment.apps/haproxy-ingress created
service/haproxy-ingress created
[root@master ~]#
```

> ![NOTA](../imgs/note-icon.png) Existen diferentes ingress controller que se pueden desplegar e incluso podemos desplegar varios que convivan en kubernetes. En este caso será necesario utilizar [annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) para especificar que ingress controller se deberá utilizar en cada deployment.

Se crea un namespace para el ingress controller:

```console
[root@master ~]# kubectl get namespaces
NAME                 STATUS   AGE
calico-system        Active   39m
default              Active   53m
haproxy-controller   Active   2m44s
kube-node-lease      Active   53m
kube-public          Active   53m
kube-system          Active   53m
tigera-operator      Active   43m
[root@master ~]# kubectl get pods --namespace=haproxy-controller
NAME                                       READY   STATUS    RESTARTS   AGE
haproxy-ingress-67f7c8b555-j7qdp           1/1     Running   0          2m55s
ingress-default-backend-78f5cc7d4c-jzfk8   1/1     Running   0          2m57s
[root@master ~]#  
```

Vemos los servicios:

```console
[root@master ~]# kubectl get svc -A
NAMESPACE            NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                                     AGE
calico-system        calico-typha              ClusterIP   10.111.29.122    <none>        5473/TCP                                    40m
default              kubernetes                ClusterIP   10.96.0.1        <none>        443/TCP                                     53m
haproxy-controller   haproxy-ingress           NodePort    10.103.225.131   <none>        80:30432/TCP,443:31967/TCP,1024:31588/TCP   3m13s
haproxy-controller   ingress-default-backend   ClusterIP   10.96.170.15     <none>        8080/TCP                                    3m15s
kube-system          kube-dns                  ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP                      53m
[root@master ~]# 
```

Según lo anterior tenemos:

+ El puerto del host **30432** se encuentra mapeado al **80** de los contenedores.
+ El puerto del host **31967** se encuentra mapeado al **443** de los contenedores.
+ El puerto del host **31588** se encuentra mapeado al **1024** de los contenedores. Este puerto se utiliza para estadísticas de haproxy.

> ![INFORMATION](../imgs/information-icon.png) [Ingress Controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/) 

> ![INFORMATION](../imgs/information-icon.png) [HAproxy ingress controller](https://github.com/haproxytech/kubernetes-ingress#readme)

## Creamos un usuario no administrador

Creamos un usuario no administrador para la gestión del clúster:

```console
[root@master ~]# useradd -md /home/kubeadmin kubeadmin
[root@master ~]# passwd kubeadmin
Changing password for user kubeadmin.
New password: 
BAD PASSWORD: The password is shorter than 8 characters
Retype new password: 
passwd: all authentication tokens updated successfully.
[root@master ~]# mkdir -p /home/kubeadmin/.kube
[root@master ~]# cp -i /etc/kubernetes/admin.conf /home/kubeadmin/.kube/config
[root@master ~]# chown kubeadmin. /home/kubeadmin/.kube/config
[root@master ~]# cat <<EOF > /etc/sudoers.d/kubeadmin
> ALL            ALL = (ALL) NOPASSWD: ALL
> EOF
[root@master ~]# 
```