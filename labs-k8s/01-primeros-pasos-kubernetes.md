# Primeros pasos con kubernetes

Revisando la configuración:

```console
[kubeadmin@kubemaster first-routed-webapp]$ kubectl config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://192.168.1.110:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
[kubeadmin@kubemaster first-routed-webapp]$ 
```

## Namespaces

Los namespaces se utilizarán para "aislar" los PODs:

```console
[kubeadmin@kubemaster ~]$ kubectl get namespaces
NAME                 STATUS   AGE
calico-system        Active   69m
default              Active   71m
haproxy-controller   Active   42m
kube-node-lease      Active   71m
kube-public          Active   71m
kube-system          Active   71m
tigera-operator      Active   71m
[kubeadmin@kubemaster ~]$
```

Los namespaces nos dan un espacio donde crear recursos y se utilizan para aislar usuarios y que cada usuario o grupo de usuario pueda desplegar sus contenedores de forma aislada con el resto.

Si no especificamos un namespace en concreto las operaciones se realizarán en el namespace **default**. Para indicar un namespace utilizaremos **--namespace=\<MI NAMESPACE\>**.

> ![INFORMATION](../imgs/information-icon.png) [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)

## PODs

Un pod es la unidad mínima de elementos que podemos desplegar.

Un POD puede estar formado por uno o varios contenedores.

```console
[kubeadmin@kubemaster ~]$ kubectl get pods
No resources found in default namespace.
[kubeadmin@kubemaster ~]$
```

Para ver los pods de un namespace:

```console
[kubeadmin@kubemaster ~]$ kubectl get pods --namespace=kube-system
NAME                                         READY   STATUS    RESTARTS   AGE
coredns-64897985d-5gfxd                      1/1     Running   2          72m
coredns-64897985d-zh2g8                      1/1     Running   2          72m
etcd-kubemaster.acme.es                      1/1     Running   2          72m
kube-apiserver-kubemaster.acme.es            1/1     Running   2          72m
kube-controller-manager-kubemaster.acme.es   1/1     Running   2          72m
kube-proxy-cn7zk                             1/1     Running   0          57m
kube-proxy-mpwzs                             1/1     Running   0          57m
kube-proxy-r5c7v                             1/1     Running   2          72m
kube-scheduler-kubemaster.acme.es            1/1     Running   2          72m
[kubeadmin@kubemaster ~]$ 
```

Con **-A** podemos ver la lista de objetos a lo largo de todos los namespaces y con **-o wide** podemos sacar más información:

```console
[kubeadmin@kubemaster ~]$ kubectl get pods -A -o wide
NAMESPACE            NAME                                                          READY   STATUS    RESTARTS   AGE   IP              NODE                 NOMINATED NODE   READINESS GATES
calico-system        calico-kube-controllers-77c48f5f64-rd8lx                      1/1     Running   1          71m   192.169.200.3   kubemaster.acme.es   <none>           <none>
calico-system        calico-node-8ktvr                                             1/1     Running   0          58m   192.168.1.112   kubenode2.acme.es    <none>           <none>
calico-system        calico-node-vhhvt                                             1/1     Running   1          71m   192.168.1.110   kubemaster.acme.es   <none>           <none>
calico-system        calico-node-vksb2                                             1/1     Running   0          58m   192.168.1.111   kubenode1.acme.es    <none>           <none>
calico-system        calico-typha-7ff47546d9-c8pf6                                 1/1     Running   0          58m   192.168.1.111   kubenode1.acme.es    <none>           <none>
calico-system        calico-typha-7ff47546d9-v58w7                                 1/1     Running   1          71m   192.168.1.110   kubemaster.acme.es   <none>           <none>
haproxy-controller   haproxy-kubernetes-ingress-54f9b477b9-tnq4r                   1/1     Running   0          44m   192.169.49.66   kubenode2.acme.es    <none>           <none>
haproxy-controller   haproxy-kubernetes-ingress-default-backend-6b7ddb86b9-qztwc   1/1     Running   0          44m   192.169.49.65   kubenode2.acme.es    <none>           <none>
kube-system          coredns-64897985d-5gfxd                                       1/1     Running   2          73m   192.169.200.2   kubemaster.acme.es   <none>           <none>
kube-system          coredns-64897985d-zh2g8                                       1/1     Running   2          73m   192.169.200.1   kubemaster.acme.es   <none>           <none>
kube-system          etcd-kubemaster.acme.es                                       1/1     Running   2          73m   192.168.1.110   kubemaster.acme.es   <none>           <none>
kube-system          kube-apiserver-kubemaster.acme.es                             1/1     Running   2          73m   192.168.1.110   kubemaster.acme.es   <none>           <none>
kube-system          kube-controller-manager-kubemaster.acme.es                    1/1     Running   2          73m   192.168.1.110   kubemaster.acme.es   <none>           <none>
kube-system          kube-proxy-cn7zk                                              1/1     Running   0          58m   192.168.1.111   kubenode1.acme.es    <none>           <none>
kube-system          kube-proxy-mpwzs                                              1/1     Running   0          58m   192.168.1.112   kubenode2.acme.es    <none>           <none>
kube-system          kube-proxy-r5c7v                                              1/1     Running   2          73m   192.168.1.110   kubemaster.acme.es   <none>           <none>
kube-system          kube-scheduler-kubemaster.acme.es                             1/1     Running   2          73m   192.168.1.110   kubemaster.acme.es   <none>           <none>
tigera-operator      tigera-operator-59fc55759-j862v                               1/1     Running   2          73m   192.168.1.110   kubemaster.acme.es   <none>           <none>
[kubeadmin@kubemaster ~]$
```

> ![INFORMATION](../imgs/information-icon.png) [PODs](https://kubernetes.io/docs/concepts/workloads/pods/)

## Deployments

Definimos de forma declarativa como se debe desplegar un POD.

```console
[kubeadmin@kubemaster ~]$ kubectl get deployment -A -o wide
NAMESPACE            NAME                                         READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS                IMAGES                                        SELECTOR
calico-system        calico-kube-controllers                      1/1     1            1           71m   calico-kube-controllers   docker.io/calico/kube-controllers:v3.22.0     k8s-app=calico-kube-controllers
calico-system        calico-typha                                 2/2     2            2           71m   calico-typha              docker.io/calico/typha:v3.22.0                k8s-app=calico-typha
haproxy-controller   haproxy-kubernetes-ingress                   1/1     1            1           45m   haproxy-ingress           haproxytech/kubernetes-ingress                run=haproxy-ingress
haproxy-controller   haproxy-kubernetes-ingress-default-backend   1/1     1            1           45m   ingress-default-backend   gcr.io/google_containers/defaultbackend:1.0   run=ingress-default-backend
kube-system          coredns                                      2/2     2            2           74m   coredns                   k8s.gcr.io/coredns/coredns:v1.8.6             k8s-app=kube-dns
tigera-operator      tigera-operator                              1/1     1            1           73m   tigera-operator           quay.io/tigera/operator:v1.25.0               name=tigera-operator
[kubeadmin@kubemaster ~]$
```

> ![INFORMATION](../imgs/information-icon.png) [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

## DaemonSets

Son un tipo especial de deployment, cada vez que se añada un nodo al clúster los pods definidos como **DaemonSet** se desplegarán de forma automática en el nodo:

```console
[kubeadmin@kubemaster ~]$ kubectl get daemonset -A
NAMESPACE       NAME                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR              AGE
calico-system   calico-node              3         3         3       3            3           kubernetes.io/os=linux     72m
calico-system   calico-windows-upgrade   0         0         0       0            0           kubernetes.io/os=windows   72m
kube-system     kube-proxy               3         3         3       3            3           kubernetes.io/os=linux     74m
[kubeadmin@kubemaster ~]$ 
```

> ![INFORMATION](../imgs/information-icon.png) [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)

## Obteniendo información de objetos

Podemos obtener información de cualquier objeto con el verbo **describe** indicando el tipo de objeto, el nombre y el namespace donde reside:

```console
[kubeadmin@kubemaster ~]$ kubectl describe deployment coredns --namespace=kube-system
Name:                   coredns
Namespace:              kube-system
CreationTimestamp:      Sun, 13 Feb 2022 23:04:20 +0100
Labels:                 k8s-app=kube-dns
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               k8s-app=kube-dns
Replicas:               2 desired | 2 updated | 2 total | 2 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  1 max unavailable, 25% max surge
Pod Template:
  Labels:           k8s-app=kube-dns
  Service Account:  coredns
  Containers:
   coredns:
    Image:       k8s.gcr.io/coredns/coredns:v1.8.6
    Ports:       53/UDP, 53/TCP, 9153/TCP
    Host Ports:  0/UDP, 0/TCP, 0/TCP
    Args:
      -conf
      /etc/coredns/Corefile
    Limits:
      memory:  170Mi
    Requests:
      cpu:        100m
      memory:     70Mi
    Liveness:     http-get http://:8080/health delay=60s timeout=5s period=10s #success=1 #failure=5
    Readiness:    http-get http://:8181/ready delay=0s timeout=1s period=10s #success=1 #failure=3
    Environment:  <none>
    Mounts:
      /etc/coredns from config-volume (ro)
  Volumes:
   config-volume:
    Type:               ConfigMap (a volume populated by a ConfigMap)
    Name:               coredns
    Optional:           false
  Priority Class Name:  system-cluster-critical
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   coredns-64897985d (2/2 replicas created)
Events:          <none>
[kubeadmin@kubemaster ~]$ 
```

## Obteniendo el yaml de un objeto

Podemos obtener el yaml de cualquier objeto con el verbo **get** indicando el tipo de objeto, el nombre, el namespace donde reside e indicando el formato de salida **-o yaml**:

```console
[kubeadmin@kubemaster ~]$ kubectl get deployment coredns --namespace=kube-system -o yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "1"
  creationTimestamp: "2022-02-13T22:04:20Z"
  generation: 1
  labels:
    k8s-app: kube-dns
  name: coredns
  namespace: kube-system
  resourceVersion: "1661"
  uid: 7f335b6a-d354-4105-85a9-ed2433835f92
...
status:
  availableReplicas: 2
  conditions:
  - lastTransitionTime: "2022-02-13T22:04:44Z"
    lastUpdateTime: "2022-02-13T22:04:44Z"
    message: Deployment has minimum availability.
    reason: MinimumReplicasAvailable
    status: "True"
    type: Available
  - lastTransitionTime: "2022-02-13T22:04:37Z"
    lastUpdateTime: "2022-02-13T22:04:44Z"
    message: ReplicaSet "coredns-64897985d" has successfully progressed.
    reason: NewReplicaSetAvailable
    status: "True"
    type: Progressing
  observedGeneration: 1
  readyReplicas: 2
  replicas: 2
  updatedReplicas: 2
[kubeadmin@kubemaster ~]$  
```

> ![HOMEWORK](../imgs/homework-icon.png) También podemos utilizar **-o json**.