# Instalando la SDN (Calico)

> ![IMPORTANT](../imgs/important-icon.png) La forma descrita aquí no es valida para una instalación en [Azure](https://docs.projectcalico.org/reference/public-cloud/azure#about-calico-on-azure). Para la instalación de la SDN en Azure ver [00-02-sdn-azure.md](00-02-sdn-azure.md).

Como SDN vamos a instalar [Calico](https://docs.projectcalico.org/).

Instalamos el operador de Tigera:

```console
[root@kubemaster ~]# kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
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
[root@kubemaster ~]#
```

Instalamos Calico junto con los custom resources que necesita. Para ello descargamos primero el fichero de definición:

```console
[root@kubemaster ~]# wget https://docs.projectcalico.org/manifests/custom-resources.yaml
[root@kubemaster ~]#
```

Y cambiamos el **cidr** para que coincida con el de nuestra red de PODs, el fichero [custom-resources.yaml](https://docs.projectcalico.org/manifests/custom-resources.yaml):

```yaml
# This section includes base Calico installation configuration.
# For more information, see: https://projectcalico.docs.tigera.io/v3.22/reference/installation/api#operator.tigera.io/v1.Installation
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

---

# This section configures the Calico API server.
# For more information, see: https://projectcalico.docs.tigera.io/v3.22/reference/installation/api#operator.tigera.io/v1.APIServer
apiVersion: operator.tigera.io/v1
kind: APIServer 
metadata: 
  name: default 
spec: {}
```

Instalamos Calico:

```console
[root@kubemaster ~]# kubectl apply -f custom-resources.yaml
installation.operator.tigera.io/default created
[root@kubemaster ~]# 
```
Después de unos minutos veremos el clúster como **Ready**:

```console
[root@kubemaster ~]# kubectl get nodes
NAME             STATUS   ROLES                  AGE   VERSION
kubemaster.acme.es   Ready    control-plane,master   18m   v1.20.2
[root@kubemaster ~]# kubectl get pods -A
NAMESPACE         NAME                                       READY   STATUS    RESTARTS   AGE
calico-system     calico-kube-controllers-546d44f5b7-szm8j   1/1     Running   0          8m3s
calico-system     calico-node-dltbq                          1/1     Running   0          8m3s
calico-system     calico-typha-5698b66ddc-5dbxs              1/1     Running   0          8m5s
kube-system       coredns-74ff55c5b-5cp24                    1/1     Running   0          21m
kube-system       coredns-74ff55c5b-w68pg                    1/1     Running   0          21m
kube-system       etcd-kubemaster.acme.es                        1/1     Running   1          21m
kube-system       kube-apiserver-kubemaster.acme.es              1/1     Running   1          21m
kube-system       kube-controller-manager-kubemaster.acme.es     1/1     Running   1          21m
kube-system       kube-proxy-fftw7                           1/1     Running   1          21m
kube-system       kube-scheduler-kubemaster.acme.es              1/1     Running   1          21m
tigera-operator   tigera-operator-657cc89589-wqgd6           1/1     Running   0          11m
[root@kubemaster ~]# 
```

Aunque hemos utilizado [Calico](https://docs.projectcalico.org/getting-started/kubernetes/) como [SDN](https://en.wikipedia.org/wiki/Software-defined_networking) podemos utilizar otras SDNs. Mas información en [Kubernetes Networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/).

Podemos ver la configuración del master de red:

```console
[root@kubemaster ~]# ip a 
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:b5:e5:fd brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.160/24 brd 192.168.1.255 scope global noprefixroute enp1s0
       valid_lft forever preferred_lft forever
    inet6 fe80::575b:3545:bbe3:d7b8/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
3: califb7b94e8489@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default 
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns ef0488ff-2306-40cd-b73e-e22e96930eb3
    inet6 fe80::ecee:eeff:feee:eeee/64 scope link 
       valid_lft forever preferred_lft forever
4: calieadd1ac9441@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default 
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns 2737497d-4870-4081-8524-892c1c490fd6
    inet6 fe80::ecee:eeff:feee:eeee/64 scope link 
       valid_lft forever preferred_lft forever
5: calieef5ab7c4dd@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default 
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns 7204c8d2-e9a8-4665-9b5b-4ac07aadadf3
    inet6 fe80::ecee:eeff:feee:eeee/64 scope link 
       valid_lft forever preferred_lft forever
6: cali4472774d629@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default 
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns 761f7fac-f20d-4803-a945-82769c314a9a
    inet6 fe80::ecee:eeff:feee:eeee/64 scope link 
       valid_lft forever preferred_lft forever
7: cali18a3987744e@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default 
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns 6d229dbc-a415-4aa0-a82a-957d73dc3bc7
    inet6 fe80::ecee:eeff:feee:eeee/64 scope link 
       valid_lft forever preferred_lft forever
10: vxlan.calico: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default 
    link/ether 66:a3:48:c8:28:0b brd ff:ff:ff:ff:ff:ff
    inet 192.169.203.64/32 scope global vxlan.calico
       valid_lft forever preferred_lft forever
    inet6 fe80::64a3:48ff:fec8:280b/64 scope link 
       valid_lft forever preferred_lft forever
[root@kubemaster ~]# 
```

> ![INFORMATION](../imgs/information-icon.png) [Calico Quickstart](https://docs.projectcalico.org/getting-started/kubernetes/quickstart)

> ![INFORMATION](../imgs/information-icon.png) [Calico Requirements](https://docs.projectcalico.org/getting-started/kubernetes/requirements)