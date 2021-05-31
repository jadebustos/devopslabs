# Instalando la SDN (Calico)

> ![IMPORTANT](../imgs/important-icon.png) La forma descrita aquí no es valida para una instalación en [Azure](https://docs.projectcalico.org/reference/public-cloud/azure#about-calico-on-azure). Para la instalación de la SDN en Azure ver [00-02-sdn-azure.md](00-02-sdn-azure.md).

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