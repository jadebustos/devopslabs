https://earthly.dev/blog/deploy-kubernetes-cri-o-container-runtime/
https://cloudyuga.guru/blogs/creating-kubernetes-cluster-with-cri-o-container-runtime/
https://devcloudjourney.hashnode.dev/install-a-kubernetes-cluster-on-centos-9

https://medium.com/@shashank.chp09/configuring-kubernetes-cluster-through-kubeadm-utility-on-centos-stream9-with-containerd-54fdd998ddb4

Troubleshoot
=============

https://stackoverflow.com/questions/56064537/how-to-remove-broken-nodes-in-kubernetes
https://stackoverflow.com/questions/35453792/pods-stuck-in-terminating-status

```console
[ansible@k8s ~]$ kubectl get pods -A -o wide
NAMESPACE            NAME                                         READY   STATUS        RESTARTS       AGE     IP               NODE                    NOMINATED NODE   READINESS GATES
calico-apiserver     calico-apiserver-5bfcc949bc-j4sq7            1/1     Running       10             4h13m   192.169.10.123   k8s.melmac.univ         <none>           <none>
calico-apiserver     calico-apiserver-5bfcc949bc-mm5zs            1/1     Running       10             4h13m   192.169.10.122   k8s.melmac.univ         <none>           <none>
calico-system        calico-kube-controllers-678646b58b-9nnkb     1/1     Running       10             4h14m   192.169.10.125   k8s.melmac.univ         <none>           <none>
calico-system        calico-node-twpgs                            1/1     Running       10             4h14m   192.168.122.81   k8s.melmac.univ         <none>           <none>
calico-system        calico-typha-7d887668d4-pdwrz                1/1     Running       20 (37s ago)   4h14m   192.168.122.81   k8s.melmac.univ         <none>           <none>
calico-system        csi-node-driver-h59dg                        2/2     Running       20             4h14m   192.169.10.121   k8s.melmac.univ         <none>           <none>
haproxy-controller   haproxy-kubernetes-ingress-bc8f75995-sqwnb   1/1     Terminating   0              3h21m   192.169.35.129   k8s-node1.melmac.univ   <none>           <none>
kube-system          coredns-668d6bf9bc-8hjjb                     1/1     Running       10             4h22m   192.169.10.124   k8s.melmac.univ         <none>           <none>
kube-system          coredns-668d6bf9bc-dhp4q                     1/1     Running       10             4h22m   192.169.10.126   k8s.melmac.univ         <none>           <none>
kube-system          etcd-k8s.melmac.univ                         1/1     Running       10             4h22m   192.168.122.81   k8s.melmac.univ         <none>           <none>
kube-system          kube-apiserver-k8s.melmac.univ               1/1     Running       10             4h22m   192.168.122.81   k8s.melmac.univ         <none>           <none>
kube-system          kube-controller-manager-k8s.melmac.univ      1/1     Running       10             4h22m   192.168.122.81   k8s.melmac.univ         <none>           <none>
kube-system          kube-proxy-trl54                             1/1     Running       10             4h22m   192.168.122.81   k8s.melmac.univ         <none>           <none>
kube-system          kube-scheduler-k8s.melmac.univ               1/1     Running       10             4h22m   192.168.122.81   k8s.melmac.univ         <none>           <none>
tigera-operator      tigera-operator-758db9758-5527h              1/1     Running       20 (34s ago)   4h17m   192.168.122.81   k8s.melmac.univ         <none>           <none>
[ansible@k8s ~]$ kubectl delete pod haproxy-kubernetes-ingress-bc8f75995-sqwnb --grace-period=0 --force --namespace haproxy-controller
Warning: Immediate deletion does not wait for confirmation that the running resource has been terminated. The resource may continue to run on the cluster indefinitely.
pod "haproxy-kubernetes-ingress-bc8f75995-sqwnb" force deleted
[ansible@k8s ~]$ kubectl get pods -A -o wide
NAMESPACE          NAME                                       READY   STATUS    RESTARTS        AGE     IP               NODE              NOMINATED NODE   READINESS GATES
calico-apiserver   calico-apiserver-5bfcc949bc-j4sq7          1/1     Running   10              4h14m   192.169.10.123   k8s.melmac.univ   <none>           <none>
calico-apiserver   calico-apiserver-5bfcc949bc-mm5zs          1/1     Running   10              4h14m   192.169.10.122   k8s.melmac.univ   <none>           <none>
calico-system      calico-kube-controllers-678646b58b-9nnkb   1/1     Running   10              4h15m   192.169.10.125   k8s.melmac.univ   <none>           <none>
calico-system      calico-node-twpgs                          1/1     Running   10              4h15m   192.168.122.81   k8s.melmac.univ   <none>           <none>
calico-system      calico-typha-7d887668d4-pdwrz              1/1     Running   20 (114s ago)   4h15m   192.168.122.81   k8s.melmac.univ   <none>           <none>
calico-system      csi-node-driver-h59dg                      2/2     Running   20              4h15m   192.169.10.121   k8s.melmac.univ   <none>           <none>
kube-system        coredns-668d6bf9bc-8hjjb                   1/1     Running   10              4h23m   192.169.10.124   k8s.melmac.univ   <none>           <none>
kube-system        coredns-668d6bf9bc-dhp4q                   1/1     Running   10              4h23m   192.169.10.126   k8s.melmac.univ   <none>           <none>
kube-system        etcd-k8s.melmac.univ                       1/1     Running   10              4h23m   192.168.122.81   k8s.melmac.univ   <none>           <none>
kube-system        kube-apiserver-k8s.melmac.univ             1/1     Running   10              4h23m   192.168.122.81   k8s.melmac.univ   <none>           <none>
kube-system        kube-controller-manager-k8s.melmac.univ    1/1     Running   10              4h23m   192.168.122.81   k8s.melmac.univ   <none>           <none>
kube-system        kube-proxy-trl54                           1/1     Running   10              4h23m   192.168.122.81   k8s.melmac.univ   <none>           <none>
kube-system        kube-scheduler-k8s.melmac.univ             1/1     Running   10              4h23m   192.168.122.81   k8s.melmac.univ   <none>           <none>
tigera-operator    tigera-operator-758db9758-5527h            1/1     Running   20 (111s ago)   4h19m   192.168.122.81   k8s.melmac.univ   <none>           <none>
[ansible@k8s ~]$ 
```

## Tareas a realizar en todos los nodos k8s

Ponemos selinux a disabled en /etc/selinux/config

```console
[root@k8s ~]# cat <<EOF > /etc/modules-load.d/crio.conf
> overlay
> br_netfilter
> EOF
[root@k8s ~]#
[root@k8s ~]# firewall-cmd --add-masquerade --permanent
success
[root@k8s ~]# firewall-cmd --reload
success
[root@k8s ~]#
```

```console
[root@k8s ~]# cat <<EOF > /etc/sysctl.d/k8s.conf
> net.bridge.bridge-nf-call-ip6tables = 1
> net.bridge.bridge-nf-call-iptables  = 1
> net.ipv4.ip_forward                 = 1
> EOF
[root@k8s ~]# 
```

```console
[root@k8s ~]# swapoff -a
```

Y comentar en /etc/fstab la entrada del swap.

```console
[root@k8s ~]# wget -O /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_9_Stream/devel:kubic:libcontainers:stable.repo
[root@k8s ~]# wget -O /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:1.28:1.28.4.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.28:/1.28.4/CentOS_9_Stream/devel:kubic:libcontainers:stable:cri-o:1.28:1.28.4.repo
```

```console
[root@k8s ~]# dnf install cri-o cri-tools -y
[root@k8s ~]# systemctl enable crio --now
```

```console
[root@k8s ~]# cat <<EOF > /etc/yum.repos.d/kubernetes.repo
> [kubernetes]
> name=Kubernetes
> baseurl=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/
> enabled=1
> gpgcheck=1
> gpgkey=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/repodata/repomd.xml.key
> exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
> EOF
[root@k8s ~]#
```

```console
[root@k8s ~]# dnf makecache ; dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
```

## Configuración en el nodo master

```console
[root@k8s ~]# firewall-cmd --permanent --add-port=6443/tcp
success
[root@k8s ~]# firewall-cmd --permanent --add-port=2379-2380/tcp
success
[root@k8s ~]# firewall-cmd --permanent --add-port=10250-10252/tcp
success
[root@k8s ~]# firewall-cmd --permanent --add-port=10255/tcp
success
[root@k8s ~]# firewall-cmd --permanent --add-port=5473/tcp
success
[root@k8s ~]# firewall-cmd --reload
success
[root@k8s ~]#
```

```console
[root@k8s ~]# systemctl enable --now kubelet.service
Created symlink /etc/systemd/system/multi-user.target.wants/kubelet.service → /usr/lib/systemd/system/kubelet.service.
[root@k8s ~]# 
```

```console
[root@k8s ~]# kubeadm config images pull
[config/images] Pulled registry.k8s.io/kube-apiserver:v1.32.1
[config/images] Pulled registry.k8s.io/kube-controller-manager:v1.32.1
[config/images] Pulled registry.k8s.io/kube-scheduler:v1.32.1
[config/images] Pulled registry.k8s.io/kube-proxy:v1.32.1
[config/images] Pulled registry.k8s.io/coredns/coredns:v1.11.3
[config/images] Pulled registry.k8s.io/pause:3.10
[config/images] Pulled registry.k8s.io/etcd:3.5.16-0
[root@k8s ~]# 
```

```console
[root@k8s ~]# kubeadm init --pod-network-cidr=192.169.0.0/16
[init] Using Kubernetes version: v1.32.1
[preflight] Running pre-flight checks
	[WARNING Firewalld]: firewalld is active, please ensure ports [6443 10250] are open or your cluster may not function correctly
	[WARNING Hostname]: hostname "k8s.melmac.univ" could not be reached
	[WARNING Hostname]: hostname "k8s.melmac.univ": lookup k8s.melmac.univ on 192.168.122.1:53: no such host
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action beforehand using 'kubeadm config images pull'
W0123 11:44:26.740217    5780 checks.go:846] detected that the sandbox image "registry.k8s.io/pause:3.9" of the container runtime is inconsistent with that used by kubeadm.It is recommended to use "registry.k8s.io/pause:3.10" as the CRI sandbox image.
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [k8s.melmac.univ kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 192.168.122.81]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [k8s.melmac.univ localhost] and IPs [192.168.122.81 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [k8s.melmac.univ localhost] and IPs [192.168.122.81 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "super-admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests"
[kubelet-check] Waiting for a healthy kubelet at http://127.0.0.1:10248/healthz. This can take up to 4m0s
[kubelet-check] The kubelet is healthy after 501.399368ms
[api-check] Waiting for a healthy API server. This can take up to 4m0s
[api-check] The API server is healthy after 4.500731927s
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node k8s.melmac.univ as control-plane by adding the labels: [node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
[mark-control-plane] Marking the node k8s.melmac.univ as control-plane by adding the taints [node-role.kubernetes.io/control-plane:NoSchedule]
[bootstrap-token] Using token: z8i0cc.e5xpwr5ahh5hmkwn
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] Configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] Configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
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

kubeadm join 192.168.122.81:6443 --token z8i0cc.e5xpwr5ahh5hmkwn \
	--discovery-token-ca-cert-hash sha256:26af0fb3982959f17c89274088bac3383672828a8755fd7d76d8e66e075f6585 
[root@k8s ~]#
```

```console
[ansible@k8s ~]$ mkdir -p .kube
[ansible@k8s ~]$ sudo cp -i /etc/kubernetes/admin.conf .kube/config
[ansible@k8s ~]$ sudo chown $(id -u):$(id -g) .kube/config
[ansible@k8s ~]$
```

## Calico

```console
[ansible@k8s ~]$ kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
namespace/tigera-operator created
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgppeers.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/blockaffinities.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/caliconodestatuses.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/clusterinformations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworksets.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/hostendpoints.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamblocks.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamconfigs.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamhandles.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipreservations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/kubecontrollersconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networksets.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/apiservers.operator.tigera.io created
customresourcedefinition.apiextensions.k8s.io/imagesets.operator.tigera.io created
customresourcedefinition.apiextensions.k8s.io/installations.operator.tigera.io created
customresourcedefinition.apiextensions.k8s.io/tigerastatuses.operator.tigera.io created
serviceaccount/tigera-operator created
clusterrole.rbac.authorization.k8s.io/tigera-operator created
clusterrolebinding.rbac.authorization.k8s.io/tigera-operator created
deployment.apps/tigera-operator created
[ansible@k8s ~]$ wget https://docs.projectcalico.org/manifests/custom-resources.yaml
...
[ansible@k8s ~]$ sed -i 's/cidr: 192\.168\.0\.0\/16/cidr: 192.169.0.0\/16/g' custom-resources.yaml
[ansible@k8s ~]$ kubectl apply -f custom-resources.yaml
installation.operator.tigera.io/default created
apiserver.operator.tigera.io/default created
[ansible@k8s ~]$ 
```

```console
[ansible@k8s ~]$ kubectl get nodes
NAME              STATUS   ROLES           AGE     VERSION
k8s.melmac.univ   Ready    control-plane   8m51s   v1.32.1
[ansible@k8s ~]$ kubectl get pods -A
NAMESPACE          NAME                                       READY   STATUS    RESTARTS   AGE
calico-apiserver   calico-apiserver-5bfcc949bc-j4sq7          1/1     Running   0          26s
calico-apiserver   calico-apiserver-5bfcc949bc-mm5zs          1/1     Running   0          26s
calico-system      calico-kube-controllers-678646b58b-9nnkb   1/1     Running   0          79s
calico-system      calico-node-twpgs                          1/1     Running   0          79s
calico-system      calico-typha-7d887668d4-pdwrz              1/1     Running   0          79s
calico-system      csi-node-driver-h59dg                      2/2     Running   0          79s
kube-system        coredns-668d6bf9bc-8hjjb                   1/1     Running   0          9m43s
kube-system        coredns-668d6bf9bc-dhp4q                   1/1     Running   0          9m43s
kube-system        etcd-k8s.melmac.univ                       1/1     Running   0          9m51s
kube-system        kube-apiserver-k8s.melmac.univ             1/1     Running   0          9m51s
kube-system        kube-controller-manager-k8s.melmac.univ    1/1     Running   0          9m49s
kube-system        kube-proxy-trl54                           1/1     Running   0          9m44s
kube-system        kube-scheduler-k8s.melmac.univ             1/1     Running   0          9m49s
tigera-operator    tigera-operator-758db9758-5527h            1/1     Running   0          5m4s
[ansible@k8s ~]$ kubectl get pods -A -o wide
NAMESPACE          NAME                                       READY   STATUS    RESTARTS      AGE   IP               NODE              NOMINATED NODE   READINESS GATES
calico-apiserver   calico-apiserver-5bfcc949bc-j4sq7          1/1     Running   3             44m   192.169.10.79    k8s.melmac.univ   <none>           <none>
calico-apiserver   calico-apiserver-5bfcc949bc-mm5zs          1/1     Running   3             44m   192.169.10.83    k8s.melmac.univ   <none>           <none>
calico-system      calico-kube-controllers-678646b58b-9nnkb   1/1     Running   3             45m   192.169.10.82    k8s.melmac.univ   <none>           <none>
calico-system      calico-node-twpgs                          1/1     Running   3             45m   192.168.122.81   k8s.melmac.univ   <none>           <none>
calico-system      calico-typha-7d887668d4-pdwrz              1/1     Running   6 (27m ago)   45m   192.168.122.81   k8s.melmac.univ   <none>           <none>
calico-system      csi-node-driver-h59dg                      2/2     Running   6             45m   192.169.10.84    k8s.melmac.univ   <none>           <none>
kube-system        coredns-668d6bf9bc-8hjjb                   1/1     Running   3             54m   192.169.10.80    k8s.melmac.univ   <none>           <none>
kube-system        coredns-668d6bf9bc-dhp4q                   1/1     Running   3             54m   192.169.10.81    k8s.melmac.univ   <none>           <none>
kube-system        etcd-k8s.melmac.univ                       1/1     Running   3             54m   192.168.122.81   k8s.melmac.univ   <none>           <none>
kube-system        kube-apiserver-k8s.melmac.univ             1/1     Running   3             54m   192.168.122.81   k8s.melmac.univ   <none>           <none>
kube-system        kube-controller-manager-k8s.melmac.univ    1/1     Running   3             54m   192.168.122.81   k8s.melmac.univ   <none>           <none>
kube-system        kube-proxy-trl54                           1/1     Running   3             54m   192.168.122.81   k8s.melmac.univ   <none>           <none>
kube-system        kube-scheduler-k8s.melmac.univ             1/1     Running   3             54m   192.168.122.81   k8s.melmac.univ   <none>           <none>
tigera-operator    tigera-operator-758db9758-5527h            1/1     Running   6 (27m ago)   49m   192.168.122.81   k8s.melmac.univ   <none>           <none>
[ansible@k8s ~]$ 
```

## Desplegando ingress

```console
[ansible@k8s ~]$ kubectl get namespaces
NAME               STATUS   AGE
calico-apiserver   Active   50m
calico-system      Active   51m
default            Active   60m
kube-node-lease    Active   60m
kube-public        Active   60m
kube-system        Active   60m
tigera-operator    Active   55m
[ansible@k8s ~]$ kubectl apply -f https://raw.githubusercontent.com/haproxytech/kubernetes-ingress/master/deploy/haproxy-ingress.yaml
namespace/haproxy-controller created
serviceaccount/haproxy-kubernetes-ingress created
clusterrole.rbac.authorization.k8s.io/haproxy-kubernetes-ingress created
clusterrolebinding.rbac.authorization.k8s.io/haproxy-kubernetes-ingress created
configmap/haproxy-kubernetes-ingress created
deployment.apps/haproxy-kubernetes-ingress created
service/haproxy-kubernetes-ingress created
[ansible@k8s ~]$ kubectl get namespaces
NAME                 STATUS   AGE
calico-apiserver     Active   51m
calico-system        Active   52m
default              Active   60m
haproxy-controller   Active   4s
kube-node-lease      Active   60m
kube-public          Active   60m
kube-system          Active   60m
tigera-operator      Active   55m
[ansible@k8s ~]$ kubectl get pods -A
NAMESPACE            NAME                                         READY   STATUS    RESTARTS      AGE
calico-apiserver     calico-apiserver-5bfcc949bc-j4sq7            1/1     Running   3             51m
calico-apiserver     calico-apiserver-5bfcc949bc-mm5zs            1/1     Running   3             51m
calico-system        calico-kube-controllers-678646b58b-9nnkb     1/1     Running   3             52m
calico-system        calico-node-r7x6l                            0/1     Running   0             4m22s
calico-system        calico-node-twpgs                            0/1     Running   3             52m
calico-system        calico-typha-7d887668d4-pdwrz                1/1     Running   6 (34m ago)   52m
calico-system        csi-node-driver-h59dg                        2/2     Running   6             52m
calico-system        csi-node-driver-p2qvl                        2/2     Running   0             4m21s
haproxy-controller   haproxy-kubernetes-ingress-bc8f75995-sqwnb   1/1     Running   0             40s
kube-system          coredns-668d6bf9bc-8hjjb                     1/1     Running   3             61m
kube-system          coredns-668d6bf9bc-dhp4q                     1/1     Running   3             61m
kube-system          etcd-k8s.melmac.univ                         1/1     Running   3             61m
kube-system          kube-apiserver-k8s.melmac.univ               1/1     Running   3             61m
kube-system          kube-controller-manager-k8s.melmac.univ      1/1     Running   3             61m
kube-system          kube-proxy-b6hvc                             1/1     Running   0             4m22s
kube-system          kube-proxy-trl54                             1/1     Running   3             61m
kube-system          kube-scheduler-k8s.melmac.univ               1/1     Running   3             61m
tigera-operator      tigera-operator-758db9758-5527h              1/1     Running   6 (34m ago)   56m
[ansible@k8s ~]$ kubectl get svc -A
NAMESPACE            NAME                              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                     AGE
calico-apiserver     calico-api                        ClusterIP   10.108.196.218   <none>        443/TCP                                     52m
calico-system        calico-kube-controllers-metrics   ClusterIP   None             <none>        9094/TCP                                    53m
calico-system        calico-typha                      ClusterIP   10.110.160.29    <none>        5473/TCP                                    53m
default              kubernetes                        ClusterIP   10.96.0.1        <none>        443/TCP                                     61m
haproxy-controller   haproxy-kubernetes-ingress        NodePort    10.103.154.78    <none>        80:32452/TCP,443:30132/TCP,1024:31904/TCP   78s
kube-system          kube-dns                          ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP                      61m
[ansible@k8s ~]$ 
```

## Configurando workers

```console
[root@k8s-node1 ~]# firewall-cmd --zone=public --permanent --add-port={10250,30000-32767}/tcp
success
[root@k8s-node1 ~]# firewall-cmd --reload
success
[root@k8s-node1 ~]# 
```

```console
[ansible@k8s ~]$ kubeadm token create --print-join-command
kubeadm join 192.168.122.81:6443 --token nh4mcy.kt48jtbvf8k62qwk --discovery-token-ca-cert-hash sha256:26af0fb3982959f17c89274088bac3383672828a8755fd7d76d8e66e075f6585 
[ansible@k8s ~]$
```

```console
[root@k8s-node1 ~]# systemctl enable kubelet.service
[root@k8s-node1 ~]# kubeadm join 192.168.122.81:6443 --token nh4mcy.kt48jtbvf8k62qwk --discovery-token-ca-cert-hash sha256:26af0fb3982959f17c89274088bac3383672828a8755fd7d76d8e66e075f6585
[preflight] Running pre-flight checks
	[WARNING Service-Kubelet]: kubelet service is not enabled, please run 'systemctl enable kubelet.service'
[preflight] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[preflight] Use 'kubeadm init phase upload-config --config your-config.yaml' to re-upload it.
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-check] Waiting for a healthy kubelet at http://127.0.0.1:10248/healthz. This can take up to 4m0s
[kubelet-check] The kubelet is healthy after 501.118313ms
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

[root@k8s-node1 ~]#
```

```console
[ansible@k8s ~]$ kubectl get nodes
NAME                    STATUS   ROLES           AGE   VERSION
k8s-node1.melmac.univ   Ready    <none>          11s   v1.32.1
k8s.melmac.univ         Ready    control-plane   57m   v1.32.1
[ansible@k8s ~]$
```


