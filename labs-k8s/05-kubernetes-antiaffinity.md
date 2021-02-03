# Reglas de afinidad

Este deployment tiene una replica, por lo tanto hay un único contenedor en el POD:

```console
[kubeadmin@master webapp-antiaffinity]$ kubectl get pods --namespace=webapp-routed -o wide
NAME                             READY   STATUS    RESTARTS   AGE   IP               NODE               NOMINATED NODE   READINESS GATES
webapp-routed-865bc5c6b4-fdqzv   1/1     Running   2          8h    192.169.112.15   worker01.acme.es   <none>           <none>
[kubeadmin@master webapp-antiaffinity]$
```

Si lo escalamos:

```console
[kubeadmin@master webapp-antiaffinity]$ kubectl scale --replicas=2 deployment/webapp-routed --namespace=webapp-routed
deployment.apps/webapp-routed scaled
[kubeadmin@master webapp-antiaffinity]$ kubectl get pods --namespace=webapp-routed -o wide
NAME                             READY   STATUS    RESTARTS   AGE   IP               NODE               NOMINATED NODE   READINESS GATES
webapp-routed-865bc5c6b4-fdqzv   1/1     Running   2          8h    192.169.112.15   worker01.acme.es   <none>           <none>
webapp-routed-865bc5c6b4-wh8gx   0/1     Running   0          12s   192.169.112.21   worker01.acme.es   <none>           <none>
[kubeadmin@master webapp-antiaffinity]$
```

> ![NOTA](../imgs/note-icon.png) Habíamos visto como escalar un deployment con **kubectl edit deployment webapp-routed --namespace=webapp-routed**.

Vemos que los dos contenedores se encuentran en el mismo nodo.

Podemos forzar a que estén separados o siempre juntos.

## Antiaffinity

Modificamos el ejemplo que teníamos para que los dos contenedores se ejecuten en workers separados:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-antiaffinity
  namespace: webapp-antiaffinity
  labels:
    app: webapp-antiaffinity
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp-antiaffinity
  template:
    metadata:
      labels:
        app: webapp-antiaffinity
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - webapp-antiaffinity
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: webapp-antiaffinity
        image: quay.io/rhte_2019/webapp:v1
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80 
          initialDelaySeconds: 5
          periodSeconds: 5
          successThreshold: 1
---
apiVersion: v1
kind: Service
metadata:
    name: webapp-antiaffinity-service
    namespace: webapp-antiaffinity
spec:
    selector:
      app: webapp-antiaffinity
    ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  namespace: webapp-antiaffinity
  labels:
    app: webapp-antiaffinity
  annotations:
      haproxy.org/path-rewrite: "/"
spec:
  rules:
  - host: foo-antiaffinity.bar
    http:
      paths:
      - path: /webapp
        pathType: "Prefix"
        backend:
          service:
            name: webapp-antiaffinity-service
            port:
              number: 80
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: haproxy-configmap
  namespace: webapp-antiaffinity
data:
  servers-increment: "42"
  ssl-redirect: "OFF"
```

Creamos el namespace, lo ejecutamos y podemos ver que los contenedores del pod se ejecutan en un diferentes nodos:

```console
[kubeadmin@master webapp-antiaffinity]$ kubectl create namespace webapp-antiaffinity
namespace/webapp-antiaffinity created
[kubeadmin@master webapp-antiaffinity]$ kubectl apply -f antiaffinity-webapp.yaml 
deployment.apps/webapp-antiaffinity created
service/webapp-antiaffinity-service created
ingress.networking.k8s.io/webapp-ingress created
configmap/haproxy-configmap created
[kubeadmin@master webapp-antiaffinity]$ kubectl get pods --namespace=webapp-antiaffinity -o wide
NAME                                   READY   STATUS    RESTARTS   AGE    IP               NODE               NOMINATED NODE   READINESS GATES
webapp-antiaffinity-59d4d57956-5wmxr   1/1     Running   0          116s   192.169.22.4     worker02.acme.es   <none>           <none>
webapp-antiaffinity-59d4d57956-7x8bc   1/1     Running   0          116s   192.169.112.20   worker01.acme.es   <none>           <none>
[kubeadmin@master webapp-antiaffinity]$
```

A continuación paramos el worker 2, esperamos un tiempo hasta que lo de por muerto (~5 minutos):

```console
[kubeadmin@master webapp-antiaffinity]$ kubectl get nodes
NAME               STATUS     ROLES                  AGE   VERSION
master.acme.es     Ready      control-plane,master   10h   v1.20.2
worker01.acme.es   Ready      <none>                 9h    v1.20.2
worker02.acme.es   NotReady   <none>                 9h    v1.20.2
[kubeadmin@master webapp-antiaffinity]$ kubectl get pods --namespace=webapp-antiaffinity -o wide
NAME                                   READY   STATUS        RESTARTS   AGE    IP               NODE               NOMINATED NODE   READINESS GATES
webapp-antiaffinity-59d4d57956-5wmxr   1/1     Terminating   0          30m    192.169.22.4     worker02.acme.es   <none>           <none>
webapp-antiaffinity-59d4d57956-7x8bc   1/1     Running       0          30m    192.169.112.20   worker01.acme.es   <none>           <none>
webapp-antiaffinity-59d4d57956-859mj   0/1     Pending       0          118s   <none>           <none>             <none>           <none>
[kubeadmin@master webapp-antiaffinity]$ kubectl get events --namespace=webapp-antiaffinity
LAST SEEN   TYPE      REASON                 OBJECT                                      MESSAGE
31m         Normal    Scheduled              pod/webapp-antiaffinity-59d4d57956-5wmxr    Successfully assigned webapp-antiaffinity/webapp-antiaffinity-59d4d57956-5wmxr to worker02.acme.es
31m         Normal    Pulling                pod/webapp-antiaffinity-59d4d57956-5wmxr    Pulling image "quay.io/rhte_2019/webapp:v1"
29m         Normal    Pulled                 pod/webapp-antiaffinity-59d4d57956-5wmxr    Successfully pulled image "quay.io/rhte_2019/webapp:v1" in 1m16.39059491s
29m         Normal    Created                pod/webapp-antiaffinity-59d4d57956-5wmxr    Created container webapp-antiaffinity
29m         Normal    Started                pod/webapp-antiaffinity-59d4d57956-5wmxr    Started container webapp-antiaffinity
7m25s       Warning   NodeNotReady           pod/webapp-antiaffinity-59d4d57956-5wmxr    Node is not ready
2m20s       Normal    TaintManagerEviction   pod/webapp-antiaffinity-59d4d57956-5wmxr    Marking for deletion Pod webapp-antiaffinity/webapp-antiaffinity-59d4d57956-5wmxr
31m         Normal    Scheduled              pod/webapp-antiaffinity-59d4d57956-7x8bc    Successfully assigned webapp-antiaffinity/webapp-antiaffinity-59d4d57956-7x8bc to worker01.acme.es
31m         Normal    Pulled                 pod/webapp-antiaffinity-59d4d57956-7x8bc    Container image "quay.io/rhte_2019/webapp:v1" already present on machine
31m         Normal    Created                pod/webapp-antiaffinity-59d4d57956-7x8bc    Created container webapp-antiaffinity
31m         Normal    Started                pod/webapp-antiaffinity-59d4d57956-7x8bc    Started container webapp-antiaffinity
2m20s       Warning   FailedScheduling       pod/webapp-antiaffinity-59d4d57956-859mj    0/3 nodes are available: 1 node(s) didn't match pod affinity/anti-affinity, 1 node(s) didn't match pod anti-affinity rules, 1 node(s) had taint {node-role.kubernetes.io/master: }, that the pod didn't tolerate, 1 node(s) had taint {node.kubernetes.io/unreachable: }, that the pod didn't tolerate.
69s         Warning   FailedScheduling       pod/webapp-antiaffinity-59d4d57956-859mj    0/3 nodes are available: 1 node(s) didn't match pod affinity/anti-affinity, 1 node(s) didn't match pod anti-affinity rules, 1 node(s) had taint {node-role.kubernetes.io/master: }, that the pod didn't tolerate, 1 node(s) had taint {node.kubernetes.io/unreachable: }, that the pod didn't tolerate.
31m         Normal    SuccessfulCreate       replicaset/webapp-antiaffinity-59d4d57956   Created pod: webapp-antiaffinity-59d4d57956-7x8bc
31m         Normal    SuccessfulCreate       replicaset/webapp-antiaffinity-59d4d57956   Created pod: webapp-antiaffinity-59d4d57956-5wmxr
2m20s       Normal    SuccessfulCreate       replicaset/webapp-antiaffinity-59d4d57956   Created pod: webapp-antiaffinity-59d4d57956-859mj
31m         Normal    ScalingReplicaSet      deployment/webapp-antiaffinity              Scaled up replica set webapp-antiaffinity-59d4d57956 to 2
[kubeadmin@master webapp-antiaffinity]$
```

Como no hay ningún worker mas y en el activo ya hay un contenedor del POD no se instancia la otra replica. Arrancamos el segundo worker:

```console
[kubeadmin@master webapp-antiaffinity]$ kubectl get nodes
NAME               STATUS   ROLES                  AGE   VERSION
master.acme.es     Ready    control-plane,master   10h   v1.20.2
worker01.acme.es   Ready    <none>                 9h    v1.20.2
worker02.acme.es   Ready    <none>                 9h    v1.20.2
[kubeadmin@master webapp-antiaffinity]$ kubectl get pods --namespace=webapp-antiaffinity -o wide
NAME                                   READY   STATUS    RESTARTS   AGE     IP               NODE               NOMINATED NODE   READINESS GATES
webapp-antiaffinity-59d4d57956-7x8bc   1/1     Running   0          35m     192.169.112.20   worker01.acme.es   <none>           <none>
webapp-antiaffinity-59d4d57956-859mj   1/1     Running   0          6m16s   192.169.22.5     worker02.acme.es   <none>           <none>
[kubeadmin@master webapp-antiaffinity]$ kubectl get events --namespace=webapp-antiaffinity
LAST SEEN   TYPE      REASON                 OBJECT                                      MESSAGE
35m         Normal    Scheduled              pod/webapp-antiaffinity-59d4d57956-5wmxr    Successfully assigned webapp-antiaffinity/webapp-antiaffinity-59d4d57956-5wmxr to worker02.acme.es
35m         Normal    Pulling                pod/webapp-antiaffinity-59d4d57956-5wmxr    Pulling image "quay.io/rhte_2019/webapp:v1"
33m         Normal    Pulled                 pod/webapp-antiaffinity-59d4d57956-5wmxr    Successfully pulled image "quay.io/rhte_2019/webapp:v1" in 1m16.39059491s
33m         Normal    Created                pod/webapp-antiaffinity-59d4d57956-5wmxr    Created container webapp-antiaffinity
33m         Normal    Started                pod/webapp-antiaffinity-59d4d57956-5wmxr    Started container webapp-antiaffinity
11m         Warning   NodeNotReady           pod/webapp-antiaffinity-59d4d57956-5wmxr    Node is not ready
6m30s       Normal    TaintManagerEviction   pod/webapp-antiaffinity-59d4d57956-5wmxr    Marking for deletion Pod webapp-antiaffinity/webapp-antiaffinity-59d4d57956-5wmxr
50s         Warning   FailedKillPod          pod/webapp-antiaffinity-59d4d57956-5wmxr    error killing pod: failed to "KillPodSandbox" for "1bb0c8bb-4989-4804-83f1-b79acbc6461a" with KillPodSandboxError: "rpc error: code = Unknown desc = networkPlugin cni failed to teardown pod \"webapp-antiaffinity-59d4d57956-5wmxr_webapp-antiaffinity\" network: error getting ClusterInformation: Get \"https://10.96.0.1:443/apis/crd.projectcalico.org/v1/clusterinformations/default\": dial tcp 10.96.0.1:443: i/o timeout"
35m         Normal    Scheduled              pod/webapp-antiaffinity-59d4d57956-7x8bc    Successfully assigned webapp-antiaffinity/webapp-antiaffinity-59d4d57956-7x8bc to worker01.acme.es
35m         Normal    Pulled                 pod/webapp-antiaffinity-59d4d57956-7x8bc    Container image "quay.io/rhte_2019/webapp:v1" already present on machine
35m         Normal    Created                pod/webapp-antiaffinity-59d4d57956-7x8bc    Created container webapp-antiaffinity
35m         Normal    Started                pod/webapp-antiaffinity-59d4d57956-7x8bc    Started container webapp-antiaffinity
6m29s       Warning   FailedScheduling       pod/webapp-antiaffinity-59d4d57956-859mj    0/3 nodes are available: 1 node(s) didn't match pod affinity/anti-affinity, 1 node(s) didn't match pod anti-affinity rules, 1 node(s) had taint {node-role.kubernetes.io/master: }, that the pod didn't tolerate, 1 node(s) had taint {node.kubernetes.io/unreachable: }, that the pod didn't tolerate.
5m19s       Warning   FailedScheduling       pod/webapp-antiaffinity-59d4d57956-859mj    0/3 nodes are available: 1 node(s) didn't match pod affinity/anti-affinity, 1 node(s) didn't match pod anti-affinity rules, 1 node(s) had taint {node-role.kubernetes.io/master: }, that the pod didn't tolerate, 1 node(s) had taint {node.kubernetes.io/unreachable: }, that the pod didn't tolerate.
40s         Warning   FailedScheduling       pod/webapp-antiaffinity-59d4d57956-859mj    0/3 nodes are available: 1 node(s) had taint {node-role.kubernetes.io/master: }, that the pod didn't tolerate, 2 node(s) didn't match pod affinity/anti-affinity, 2 node(s) didn't match pod anti-affinity rules.
30s         Normal    Scheduled              pod/webapp-antiaffinity-59d4d57956-859mj    Successfully assigned webapp-antiaffinity/webapp-antiaffinity-59d4d57956-859mj to worker02.acme.es
28s         Normal    Pulled                 pod/webapp-antiaffinity-59d4d57956-859mj    Container image "quay.io/rhte_2019/webapp:v1" already present on machine
28s         Normal    Created                pod/webapp-antiaffinity-59d4d57956-859mj    Created container webapp-antiaffinity
27s         Normal    Started                pod/webapp-antiaffinity-59d4d57956-859mj    Started container webapp-antiaffinity
35m         Normal    SuccessfulCreate       replicaset/webapp-antiaffinity-59d4d57956   Created pod: webapp-antiaffinity-59d4d57956-7x8bc
35m         Normal    SuccessfulCreate       replicaset/webapp-antiaffinity-59d4d57956   Created pod: webapp-antiaffinity-59d4d57956-5wmxr
6m30s       Normal    SuccessfulCreate       replicaset/webapp-antiaffinity-59d4d57956   Created pod: webapp-antiaffinity-59d4d57956-859mj
35m         Normal    ScalingReplicaSet      deployment/webapp-antiaffinity              Scaled up replica set webapp-antiaffinity-59d4d57956 to 2
[kubeadmin@master webapp-antiaffinity]$ 
```

> ![INFORMATION](../imgs/information-icon.png) [Assign pod to node](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)

> ![INFORMATION](../imgs/information-icon.png) [POD Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)

> ![INFORMATION](../imgs/information-icon.png) [Pod Topology Spread Constraints](https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/)

> ![INFORMATION](../imgs/information-icon.png) [Advanced Scheduling in Kubernetes](https://kubernetes.io/blog/2017/03/advanced-scheduling-in-kubernetes/)

## Affinity

Cuando queramos que los contenedores del POD se ejecuten siempre en el mismo worker tendremos que poner una regla de afinidad. Es procedimiento es el mismo y la regla:

```yaml
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - webapp-antiaffinity
            topologyKey: "kubernetes.io/hostname"
```