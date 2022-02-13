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

> ![INFORMATION](../imgs/information-icon.png) [Calico Quickstart](https://docs.projectcalico.org/getting-started/kubernetes/quickstart)

> ![INFORMATION](../imgs/information-icon.png) [Calico Requirements](https://docs.projectcalico.org/getting-started/kubernetes/requirements)