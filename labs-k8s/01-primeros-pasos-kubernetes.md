# Primeros pasos con kubernetes

Revisando la configuración:

```console
[kubeadmin@master first-routed-webapp]$ kubectl config view
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
[kubeadmin@master first-routed-webapp]$ 
```

## Namespaces

Los namespaces se utilizarán para "aislar" los PODs:

```console
[kubeadmin@master k8slab]$ kubectl get namespaces
NAME                 STATUS   AGE
calico-system        Active   44m
default              Active   58m
haproxy-controller   Active   7m51s
kube-node-lease      Active   58m
kube-public          Active   58m
kube-system          Active   58m
tigera-operator      Active   48m
[kubeadmin@master k8slab]$
```

Los namespaces nos dan un espacio donde crear recursos y se utilizan para aislar usuarios y que cada usuario o grupo de usuario pueda desplegar sus contenedores de forma aislada con el resto.

Si no especificamos un namespace en concreto las operaciones se realizarán en el namespace **default**. Para indicar un namespace utilizaremos **-namespace=<MI NAMESPACE>.

> ![INFORMATION](../imgs/information-icon.png) [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)

## PODs

Un pod es la unidad mínima de elementos que podemos desplegar.

Un POD puede estar formado por uno o varios contenedores.

```console
[kubeadmin@master k8slab]$ kubectl get pods
No resources found in default namespace.
[kubeadmin@master k8slab]$
```

Para ver los pods de un namespace:

```console
[kubeadmin@master k8slab]$ kubectl get pods --namespace=kube-system
NAME                                       READY   STATUS    RESTARTS   AGE
coredns-74ff55c5b-5cp24                  1/1     Running   0          58m
coredns-74ff55c5b-w68pg                  1/1     Running   0          58m
etcd-master.acme.es                      1/1     Running   1          58m
kube-apiserver-master.acme.es            1/1     Running   1          58m
kube-controller-manager-master.acme.es   1/1     Running   1          58m
kube-proxy-bm6fs                         1/1     Running   0          34m
kube-proxy-cd2xq                         1/1     Running   0          34m
kube-proxy-fftw7                         1/1     Running   1          58m
kube-scheduler-master.acme.es            1/1     Running   1          58m
[kubeadmin@master k8slab]$ 
```

Con **-A** podemos ver la lista de objetos a lo largo de todos los namespaces y con **-o wide** podemos sacar más información:

```console
[kubeadmin@master k8slab]$ kubectl get pods -A -o wide
NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE   IP              NODE               NOMINATED NODE   READINESS GATES
calico-system        calico-kube-controllers-546d44f5b7-szm8j   1/1     Running   0          45m     192.169.121.67   master.acme.es     <none>           <none>
calico-system        calico-node-dltbq                          1/1     Running   0          45m     192.168.1.110    master.acme.es     <none>           <none>
calico-system        calico-node-h86k4                          1/1     Running   0          35m     192.168.1.112    worker02.acme.es   <none>           <none>
calico-system        calico-node-xkxgw                          1/1     Running   0          35m     192.168.1.111    worker01.acme.es   <none>           <none>
calico-system        calico-typha-5698b66ddc-5dbxs              1/1     Running   0          45m     192.168.1.110    master.acme.es     <none>           <none>
calico-system        calico-typha-5698b66ddc-6nzxw              1/1     Running   0          34m     192.168.1.111    worker01.acme.es   <none>           <none>
calico-system        calico-typha-5698b66ddc-lsj8t              1/1     Running   0          34m     192.168.1.112    worker02.acme.es   <none>           <none>
haproxy-controller   haproxy-ingress-67f7c8b555-j7qdp           1/1     Running   0          8m44s   192.169.22.1     worker02.acme.es   <none>           <none>
haproxy-controller   ingress-default-backend-78f5cc7d4c-jzfk8   1/1     Running   0          8m46s   192.169.112.1    worker01.acme.es   <none>           <none>
kube-system          coredns-74ff55c5b-5cp24                    1/1     Running   0          59m     192.169.121.65   master.acme.es     <none>           <none>
kube-system          coredns-74ff55c5b-w68pg                    1/1     Running   0          59m     192.169.121.66   master.acme.es     <none>           <none>
kube-system          etcd-master.acme.es                        1/1     Running   1          59m     192.168.1.110    master.acme.es     <none>           <none>
kube-system          kube-apiserver-master.acme.es              1/1     Running   1          59m     192.168.1.110    master.acme.es     <none>           <none>
kube-system          kube-controller-manager-master.acme.es     1/1     Running   1          59m     192.168.1.110    master.acme.es     <none>           <none>
kube-system          kube-proxy-bm6fs                           1/1     Running   0          35m     192.168.1.112    worker02.acme.es   <none>           <none>
kube-system          kube-proxy-cd2xq                           1/1     Running   0          35m     192.168.1.111    worker01.acme.es   <none>           <none>
kube-system          kube-proxy-fftw7                           1/1     Running   1          59m     192.168.1.110    master.acme.es     <none>           <none>
kube-system          kube-scheduler-master.acme.es              1/1     Running   1          59m     192.168.1.110    master.acme.es     <none>           <none>
tigera-operator      tigera-operator-657cc89589-wqgd6           1/1     Running   0          48m     192.168.1.110    master.acme.es     <none>           <none>
[kubeadmin@master k8slab]$
```

> ![INFORMATION](../imgs/information-icon.png) [PODs](https://kubernetes.io/docs/concepts/workloads/pods/)

## Deployments

Definimos de forma declarativa como se debe desplegar un POD.

```console
[kubeadmin@master k8slab]$ kubectl get deployment -A -o wide
NAMESPACE     NAME                      READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS                IMAGES                                      SELECTOR
calico-system        calico-kube-controllers   1/1     1            1           46m    calico-kube-controllers   docker.io/calico/kube-controllers:v3.17.1     k8s-app=calico-kube-controllers
calico-system        calico-typha              3/3     3            3           46m    calico-typha              docker.io/calico/typha:v3.17.1                k8s-app=calico-typha
haproxy-controller   haproxy-ingress           1/1     1            1           9m8s   haproxy-ingress           haproxytech/kubernetes-ingress                run=haproxy-ingress
haproxy-controller   ingress-default-backend   1/1     1            1           9m9s   ingress-default-backend   gcr.io/google_containers/defaultbackend:1.0   run=ingress-default-backend
kube-system          coredns                   2/2     2            2           59m    coredns                   k8s.gcr.io/coredns:1.7.0                      k8s-app=kube-dns
tigera-operator      tigera-operator           1/1     1            1           49m    tigera-operator           quay.io/tigera/operator:v1.13.2               name=tigera-operator
[kubeadmin@master k8slab]$
```

> ![INFORMATION](../imgs/information-icon.png) [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

## DaemonSets

Son un tipo especial de deployment, cada vez que se añada un nodo al clúster los pods definidos como **DaemonSet** se desplegarán de forma automática en el nodo:

```console
[kubeadmin@master k8slab]$ kubectl get daemonset -A
NAMESPACE     NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
calico-system   calico-node   3         3         3       3            3           kubernetes.io/os=linux   46m
kube-system     kube-proxy    3         3         3       3            3           kubernetes.io/os=linux   60m
[kubeadmin@master k8slab]$ 
```

> ![INFORMATION](../imgs/information-icon.png) [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)

## Obteniendo información de objetos

Podemos obtener información de cualquier objeto con el verbo **describe** indicando el tipo de objeto, el nombre y el namespace donde reside:

```console
[kubeadmin@master k8slab]$ kubectl describe deployment coredns --namespace=kube-system
Name:                   coredns
Namespace:              kube-system
CreationTimestamp:      Mon, 25 Jan 2021 06:09:24 +0100
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
    Image:       k8s.gcr.io/coredns:1.7.0
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
NewReplicaSet:   coredns-74ff55c5b (2/2 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  60m   deployment-controller  Scaled up replica set coredns-74ff55c5b to 2
[kubeadmin@master k8slab]$ 
```

## Obteniendo el yaml de un objeto

Podemos obtener el yaml de cualquier objeto con el verbo **get** indicando el tipo de objeto, el nombre, el namespace donde reside e indicando el formato de salida **-o yaml**:

```console
[kubeadmin@master k8slab]$ kubectl get deployment coredns --namespace=kube-system -o yaml
metadata:
  annotations:
    deployment.kubernetes.io/revision: "1"
  creationTimestamp: "2021-01-25T05:09:24Z"
  generation: 1
  labels:
    k8s-app: kube-dns
...
status:
  availableReplicas: 2
  conditions:
  - lastTransitionTime: "2021-01-25T05:29:49Z"
    lastUpdateTime: "2021-01-25T05:29:49Z"
    message: Deployment has minimum availability.
    reason: MinimumReplicasAvailable
    status: "True"
    type: Available
  - lastTransitionTime: "2021-01-25T05:29:49Z"
    lastUpdateTime: "2021-01-25T05:29:49Z"
    message: ReplicaSet "coredns-74ff55c5b" has successfully progressed.
    reason: NewReplicaSetAvailable
    status: "True"
    type: Progressing
  observedGeneration: 1
  readyReplicas: 2
  replicas: 2
  updatedReplicas: 2
[kubeadmin@master k8slab]$  
```

> ![NOTA](../imgs/note-icon.png): También podemos utilizar **-o json**.