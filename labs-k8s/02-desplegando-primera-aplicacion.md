# Desplegando primera aplicación

Creamos el fichero [first-app.yaml](first-app/first-app.yaml):

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: first-app
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: first-app
  labels:
    app: webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: quay.io/rhte_2019/webapp:v1      
        ports:
        - containerPort: 80

```

Este fichero define el deployment:

```yaml
    spec:
      containers:
      - name: webapp
        image: quay.io/rhte_2019/webapp:v1      
        ports:
        - containerPort: 80
```

+ **quay.io/rhte_2019/php:7-apache** se descarga la imagen del repositorio especificado.
+ Si quisieramos utilizar DockerHub pondríamos **docker.io/jadebustos2/php:7-apache**
+ Las descargas anónimas de DockerHub están [limitadas](https://www.docker.com/increase-rate-limits) y si hacemos muchos despliegues, pull, nos pueden fallar.
+ Cambia la imagen anterior por una que tengas en tu repositorio.

Para realizar el deployment:

```console
[kubeadmin@kubemaster first-app]$ kubectl apply -f first-app.yaml
...
[kubeadmin@kubemaster first-app]$
```

Depués de crear el deployment:

```console
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app
NAME                      READY   STATUS    RESTARTS   AGE
webapp-6857ff4857-fx5jx   1/1     Running   0          35s
[kubeadmin@kubemaster first-app]$ kubectl describe pod webapp-6857ff4857-fx5jx --namespace=first-app
Name:         webapp-6857ff4857-fx5jx
Namespace:    first-app
Priority:     0
Node:         kubenode1.acme.es/192.168.1.111
Start Time:   Mon, 14 Feb 2022 00:22:51 +0100
Labels:       app=webapp
              pod-template-hash=6857ff4857
Annotations:  cni.projectcalico.org/containerID: 55e70fe7baff17004012b43c32c97e1b79528b2e1d965be8e1ed2139ffc00e94
              cni.projectcalico.org/podIP: 192.169.232.1/32
              cni.projectcalico.org/podIPs: 192.169.232.1/32
Status:       Running
IP:           192.169.232.1
IPs:
  IP:           192.169.232.1
Controlled By:  ReplicaSet/webapp-6857ff4857
Containers:
  webapp:
    Container ID:   cri-o://302cec01f09a205a87b9edb0b33461c79da39bf34f599ec39ac77f33d38d2269
    Image:          quay.io/rhte_2019/webapp:v1
    Image ID:       quay.io/rhte_2019/webapp@sha256:d51ff7792bdd9a6e70b6e151adf47f357e6fd6830fceaf403f7c66e34ed367b2
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Mon, 14 Feb 2022 00:23:22 +0100
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-splmh (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  kube-api-access-splmh:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  99s   default-scheduler  Successfully assigned first-app/webapp-6857ff4857-fx5jx to kubenode1.acme.es
  Normal  Pulling    97s   kubelet            Pulling image "quay.io/rhte_2019/webapp:v1"
  Normal  Pulled     68s   kubelet            Successfully pulled image "quay.io/rhte_2019/webapp:v1" in 29.067822226s
  Normal  Created    68s   kubelet            Created container webapp
  Normal  Started    68s   kubelet            Started container webapp
[kubeadmin@kubemaster first-app]$ 
```

Podemos ver los eventos del namespace para ver que está pasando:

```console
[kubeadmin@kubemaster first-app]$ kubectl get events --namespace=first-app
LAST SEEN   TYPE     REASON              OBJECT                         MESSAGE
2m6s        Normal   Scheduled           pod/webapp-6857ff4857-fx5jx    Successfully assigned first-app/webapp-6857ff4857-fx5jx to kubenode1.acme.es
2m4s        Normal   Pulling             pod/webapp-6857ff4857-fx5jx    Pulling image "quay.io/rhte_2019/webapp:v1"
95s         Normal   Pulled              pod/webapp-6857ff4857-fx5jx    Successfully pulled image "quay.io/rhte_2019/webapp:v1" in 29.067822226s
95s         Normal   Created             pod/webapp-6857ff4857-fx5jx    Created container webapp
95s         Normal   Started             pod/webapp-6857ff4857-fx5jx    Started container webapp
2m6s        Normal   SuccessfulCreate    replicaset/webapp-6857ff4857   Created pod: webapp-6857ff4857-fx5jx
2m6s        Normal   ScalingReplicaSet   deployment/webapp              Scaled up replica set webapp-6857ff4857 to 1.
[kubeadmin@kubemaster first-app]$ 
```

Podemos consultar el yaml del pod:

```console
[kubeadmin@kubemaster first-app]$ kubectl get pod webapp-6857ff4857-fx5jx -o yaml > webapp-6857ff4857-fx5jx.yaml
```
> ![HOMEWORK](../imgs/homework-icon.png) Probar con **-o json**.

## Borrando objetos en kubernetes

Podemos borrar el pod:

```console
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app
NAME                      READY   STATUS    RESTARTS   AGE
webapp-6857ff4857-fx5jx   1/1     Running   0          83s
[kubeadmin@kubemaster first-app]$ kubectl delete pods webapp-6857ff4857-fx5jx --namespace=first-app
pod "webapp-6857ff4857-ngxfx" deleted
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app
NAME                      READY   STATUS    RESTARTS   AGE
webapp-6857ff4857-ksxz6   1/1     Running   0          27s
[kubeadmin@kubemaster first-app]$ 
```

Vemos que existe todavía, pero si nos fijamos tiene un nombre diferente:

```console
[kubeadmin@kubemaster first-app]$ kubectl get events --namespace=first-app
LAST SEEN   TYPE     REASON              OBJECT                         MESSAGE
4m53s       Normal   Scheduled           pod/webapp-6857ff4857-fx5jx    Successfully assigned first-app/webapp-6857ff4857-fx5jx to kubenode1.acme.es
4m51s       Normal   Pulling             pod/webapp-6857ff4857-fx5jx    Pulling image "quay.io/rhte_2019/webapp:v1"
4m22s       Normal   Pulled              pod/webapp-6857ff4857-fx5jx    Successfully pulled image "quay.io/rhte_2019/webapp:v1" in 29.067822226s
4m22s       Normal   Created             pod/webapp-6857ff4857-fx5jx    Created container webapp
4m22s       Normal   Started             pod/webapp-6857ff4857-fx5jx    Started container webapp
87s         Normal   Killing             pod/webapp-6857ff4857-fx5jx    Stopping container webapp
87s         Normal   Scheduled           pod/webapp-6857ff4857-ksxz6    Successfully assigned first-app/webapp-6857ff4857-ksxz6 to kubenode1.acme.es
86s         Normal   Pulled              pod/webapp-6857ff4857-ksxz6    Container image "quay.io/rhte_2019/webapp:v1" already present on machine
86s         Normal   Created             pod/webapp-6857ff4857-ksxz6    Created container webapp
86s         Normal   Started             pod/webapp-6857ff4857-ksxz6    Started container webapp
4m53s       Normal   SuccessfulCreate    replicaset/webapp-6857ff4857   Created pod: webapp-6857ff4857-fx5jx
87s         Normal   SuccessfulCreate    replicaset/webapp-6857ff4857   Created pod: webapp-6857ff4857-ksxz6
4m53s       Normal   ScalingReplicaSet   deployment/webapp              Scaled up replica set webapp-6857ff4857 to 1
[kubeadmin@kubemaster first-app]$
```

Como en el deployment se le indicaba que el número de replicas era 1 cuando el POD muere kubernetes los reinicia de forma automática:

```yaml
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
```

Para borrar la aplicación deberemos borrar el deployment:

```console
[kubeadmin@kubemaster first-app]$ kubectl get deployments --namespace=first-app
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
webapp   1/1     1            1           5m22s
[kubeadmin@kubemaster first-app]$ kubectl delete deployments webapp --namespace=first-app
deployment.apps "webapp" deleted
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app
NAME                      READY   STATUS        RESTARTS   AGE
webapp-68965f4fcc-vfgsnwebapp-586c6d8b87-b5n5g
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app
NAME                      READY   STATUS        RESTARTS   AGE
webapp-6857ff4857-ksxz6   1/1     Terminating   0          2m34s
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app
No resources found in first-app namespace.
[kubeadmin@kubemaster first-app]$ 
```

## Escalando un deployment

> ![TIP](imgs/tip-icon.png) Si borraste el deployment en el paso anterior tendrás que volver a desplegarlo.

Para escalar un deployment:

```console
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app
NAME                      READY   STATUS    RESTARTS   AGE
webapp-6857ff4857-wfhz5   1/1     Running   0          15s
[kubeadmin@kubemaster first-app]$ kubectl edit deployment webapp --namespace=first-app
```

Editará el deployment en el editor por defecto. Iremos a las especificaciones y en el campo **replica** especificaremos cuantas replicas queremos:

```yaml
spec:
  progressDeadlineSeconds: 600
  replicas: 2
```

Guardamos los cambios y salimos:

```console
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app -o wide
NAME                      READY   STATUS    RESTARTS   AGE   IP              NODE                NOMINATED NODE   READINESS GATES
webapp-6857ff4857-2gphd   1/1     Running   0          40s   192.169.49.67   kubenode2.acme.es   <none>           <none>
webapp-6857ff4857-wfhz5   1/1     Running   0          2m    192.169.232.3   kubenode1.acme.es   <none>           <none>
[kubeadmin@kubemaster first-app]$ 
```

Como ambos contenedores se están ejecutando en diferentes workers vamos a uno de ellos y hacemos un ping a sus ips:

```console
[root@kubenode1 ~]# ping -c 4 192.169.49.67
PING 192.169.49.67 (192.169.49.67) 56(84) bytes of data.
64 bytes from 192.169.49.67: icmp_seq=1 ttl=63 time=0.748 ms
64 bytes from 192.169.49.67: icmp_seq=2 ttl=63 time=0.619 ms
64 bytes from 192.169.49.67: icmp_seq=3 ttl=63 time=0.512 ms
64 bytes from 192.169.49.67: icmp_seq=4 ttl=63 time=0.456 ms

--- 192.169.49.67 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3065ms
rtt min/avg/max/mdev = 0.456/0.583/0.748/0.115 ms
[root@kubenode1 ~]# ping -c 4 192.169.232.3
PING 192.169.232.3 (192.169.232.3) 56(84) bytes of data.
64 bytes from 192.169.232.3: icmp_seq=1 ttl=64 time=0.153 ms
64 bytes from 192.169.232.3: icmp_seq=2 ttl=64 time=0.135 ms
64 bytes from 192.169.232.3: icmp_seq=3 ttl=64 time=0.106 ms
64 bytes from 192.169.232.3: icmp_seq=4 ttl=64 time=0.098 ms

--- 192.169.232.3 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3115ms
rtt min/avg/max/mdev = 0.098/0.123/0.153/0.022 ms
[root@kubenode1 ~]# 
```

Borramos uno de los pods:

```console
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app 
NAME                      READY   STATUS    RESTARTS   AGE   IP              NODE                NOMINATED NODE   READINESS GATES
webapp-6857ff4857-2gphd   1/1     Running   0          2m38s 192.169.49.67   kubenode2.acme.es   <none>           <none>
webapp-6857ff4857-wfhz5   1/1     Running   0          3m58s 192.169.232.3   kubenode1.acme.es   <none>           <none>
[kubeadmin@kubemaster first-app]$ kubectl delete pod webapp-6857ff4857-2gphd --namespace=first-app
pod "webapp-6857ff4857-2gphd" deleted
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app -o wide
NAME                      READY   STATUS    RESTARTS   AGE    IP              NODE                NOMINATED NODE   READINESS GATES
webapp-6857ff4857-84jxg   1/1     Running   0          35s    192.169.49.68   kubenode2.acme.es   <none>           <none>
webapp-6857ff4857-wfhz5   1/1     Running   0          5m4s   192.169.232.3   kubenode1.acme.es   <none>           <none>
[kubeadmin@kubemaster first-app]$
```

Vemos como automáticamente kubernetes instancia un nuevo contenedor ya que el deployment indica que tiene que haber dos replicas.