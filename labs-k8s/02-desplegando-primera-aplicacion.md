# Desplegando primera aplicación

Creamos el fichero [first-app.yaml](first-app/first-app.yaml):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
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
[kubeadmin@master first-app]$ kubectl apply -f first-app.yaml
...
[kubeadmin@master first-app]$
```

Depués de crear el deployment:

```console
[kubeadmin@master first-app]$ kubectl get pods --namespace=default
NAME                      READY   STATUS              RESTARTS   AGE
webapp-586c6d8b87-gccnl   1/1     Running   0          59s
[kubeadmin@master first-app]$ kubectl describe pod webapp-586c6d8b87-gccnl
Name:         webapp-586c6d8b87-gccnl
Namespace:    default
Priority:     0
Node:         worker01.acme.es/192.168.1.111
Start Time:   Mon, 25 Jan 2021 07:13:36 +0100
Labels:       app=webapp
              pod-template-hash=586c6d8b87
Annotations:  cni.projectcalico.org/podIP: 192.169.112.2/32
              cni.projectcalico.org/podIPs: 192.169.112.2/32
Status:       Running
IP:           192.169.112.2
IPs:
  IP:           192.169.112.2
Controlled By:  ReplicaSet/webapp-586c6d8b87
Containers:
  webapp:
    Container ID:   docker://b03177a9ce03f11ff962b237349aa2b9478789daaa5a7f23a2b2d9ab7919449b
    Image:          quay.io/rhte_2019/webapp:v1
    Image ID:       docker-pullable://quay.io/rhte_2019/webapp@sha256:064457839f9c0cee0e1b05c2cf82f94c0443030d96680250c607651c4901948a
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Mon, 25 Jan 2021 07:14:32 +0100
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-5rd46 (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  default-token-5rd46:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-5rd46
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                 node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  85s   default-scheduler  Successfully assigned default/webapp-586c6d8b87-gccnl to worker01.acme.es
  Normal  Pulling    83s   kubelet            Pulling image "quay.io/rhte_2019/webapp:v1"
  Normal  Pulled     35s   kubelet            Successfully pulled image "quay.io/rhte_2019/webapp:v1" in 47.800266489s
  Normal  Created    30s   kubelet            Created container webapp
  Normal  Started    30s   kubelet            Started container webapp
[kubeadmin@master first-app]$ 
```

Podemos ver los eventos del namespace para ver que está pasando:

```console
[kubeadmin@master first-app]$ kubectl get events --namespace=default
LAST SEEN   TYPE      REASON                    OBJECT                         MESSAGE
...
3m2s        Normal   Scheduled                 pod/webapp-586c6d8b87-gccnl    Successfully assigned default/webapp-586c6d8b87-gccnl to worker01.acme.es
3m          Normal   Pulling                   pod/webapp-586c6d8b87-gccnl    Pulling image "quay.io/rhte_2019/webapp:v1"
2m12s       Normal   Pulled                    pod/webapp-586c6d8b87-gccnl    Successfully pulled image "quay.io/rhte_2019/webapp:v1" in 47.800266489s
2m7s        Normal   Created                   pod/webapp-586c6d8b87-gccnl    Created container webapp
2m7s        Normal   Started                   pod/webapp-586c6d8b87-gccnl    Started container webapp
3m3s        Normal   SuccessfulCreate          replicaset/webapp-586c6d8b87   Created pod: webapp-586c6d8b87-gccnl
3m3s        Normal   ScalingReplicaSet         deployment/webapp              Scaled up replica set webapp-586c6d8b87 to 1
...
[kubeadmin@master first-app]$ 
```

Podemos consultar el yaml del pod:

```console
[kubeadmin@master first-app]$ kubectl get pod webapp-586c6d8b87-gccnl -o yaml > webapp-586c6d8b87-gccnl.yaml
```

> ![TIP](../imgs/tip-icon.png) Probar con **-o json**.

## Borrando objetos en kubernetes

Podemos borrar el pod:

```console
[kubeadmin@master first-app]$ kubectl get pods --namespace=default
NAME                      READY   STATUS    RESTARTS   AGE
webapp-586c6d8b87-gccnl   1/1     Running   0          5m5s
[kubeadmin@master first-app]$ kubectl delete pods webapp-68965f4fcc-bz87h --namespace=default
pod "webapp-586c6d8b87-gccnl" deleted
[kubeadmin@master first-app]$ kubectl get pods --namespace=default
NAME                      READY   STATUS    RESTARTS   AGE
webapp-586c6d8b87-b5n5g   1/1     Running   0          100s
[kubeadmin@master first-app]$ 
```

Vemos que existe todavía, pero si nos fijamos tiene un nombre diferente:

```console
[kubeadmin@master first-app]$ kubectl get events --namespace=default
LAST SEEN   TYPE     REASON             OBJECT                         MESSAGE
...
2m25s       Normal   Scheduled                 pod/webapp-586c6d8b87-b5n5g    Successfully assigned default/webapp-586c6d8b87-b5n5g to worker01.acme.es
2m22s       Normal   Pulled                    pod/webapp-586c6d8b87-b5n5g    Container image "quay.io/rhte_2019/webapp:v1" already present on machine
2m21s       Normal   Created                   pod/webapp-586c6d8b87-b5n5g    Created container webapp
2m21s       Normal   Started                   pod/webapp-586c6d8b87-b5n5g    Started container webapp
7m59s       Normal   Scheduled                 pod/webapp-586c6d8b87-gccnl    Successfully assigned default/webapp-586c6d8b87-gccnl to worker01.acme.es
7m57s       Normal   Pulling                   pod/webapp-586c6d8b87-gccnl    Pulling image "quay.io/rhte_2019/webapp:v1"
7m9s        Normal   Pulled                    pod/webapp-586c6d8b87-gccnl    Successfully pulled image "quay.io/rhte_2019/webapp:v1" in 47.800266489s
7m4s        Normal   Created                   pod/webapp-586c6d8b87-gccnl    Created container webapp
7m4s        Normal   Started                   pod/webapp-586c6d8b87-gccnl    Started container webapp
2m26s       Normal   Killing                   pod/webapp-586c6d8b87-gccnl    Stopping container webapp
8m          Normal   SuccessfulCreate          replicaset/webapp-586c6d8b87   Created pod: webapp-586c6d8b87-gccnl
2m25s       Normal   SuccessfulCreate          replicaset/webapp-586c6d8b87   Created pod: webapp-586c6d8b87-b5n5g
8m          Normal   ScalingReplicaSet         deployment/webapp              Scaled up replica set webapp-586c6d8b87 to 1
...
[kubeadmin@master first-app]$
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
[kubeadmin@master first-app]$ kubectl get deployments
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
webapp   1/1     1            1           108m
[kubeadmin@master first-app]$ kubectl delete deployments webapp
deployment.apps "webapp" deleted
[kubeadmin@master first-app]$ kubectl get pods --namespace=default
NAME                      READY   STATUS        RESTARTS   AGE
webapp-68965f4fcc-vfgsnwebapp-586c6d8b87-b5n5g
[kubeadmin@master first-app]$ kubectl get pods --namespace=default
No resources found in default namespace.
[kubeadmin@master first-app]$ 
```

## Escalando un deployment

Para escalar un deployment:

```console
[kubeadmin@master first-app]$ kubectl get pods --namespace=default
NAME                      READY   STATUS    RESTARTS   AGE
webapp-586c6d8b87-b5n5g   1/1     Running   0          4m39s
[kubeadmin@master first-app]$ kubectl get deployments --namespace=default
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
webapp   1/1     1            1           11m
[kubeadmin@master first-app]$ kubectl edit deployment webapp --namespace=default
```

Editará el deployment en el editor por defecto. Iremos a las especificaciones y en el campo **replica** especificaremos cuantas replicas queremos:

```yaml
spec:
  progressDeadlineSeconds: 600
  replicas: 2
```

Guardamos los cambios y salimos:

```console
[kubeadmin@master first-app]$ kubectl get pods --namespace=default
NAME                      READY   STATUS              RESTARTS   AGE
webapp-586c6d8b87-2xr5r   0/1     ContainerCreating   0          4s
webapp-586c6d8b87-b5n5g   1/1     Running             0          6m53s
[kubeadmin@master first-app]$ kubectl get pods --namespace=default -o wide
NAME                      READY   STATUS    RESTARTS   AGE     IP              NODE               NOMINATED NODE   READINESS GATES
webapp-586c6d8b87-2xr5r   1/1     Running   0          102s    192.169.112.4   worker01.acme.es   <none>           <none>
webapp-586c6d8b87-b5n5g   1/1     Running   0          8m31s   192.169.112.3   worker01.acme.es   <none>           <none>
[kubeadmin@master first-app]$ 
```

Como ambos contenedores se están ejecutando en el **worker01** vamos al **worker02** y hacemos un ping a sus ips:

```console
[root@worker02 ~]# ping -c 4 192.169.112.4
PING 192.169.112.4 (192.169.112.4) 56(84) bytes of data.
64 bytes from 192.169.112.4: icmp_seq=1 ttl=63 time=0.744 ms
64 bytes from 192.169.112.4: icmp_seq=2 ttl=63 time=0.603 ms
64 bytes from 192.169.112.4: icmp_seq=3 ttl=63 time=1.91 ms
64 bytes from 192.169.112.4: icmp_seq=4 ttl=63 time=1.00 ms

--- 192.169.112.4 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3029ms
rtt min/avg/max/mdev = 0.603/1.064/1.911/0.510 ms
[root@worker02 ~]# ping -c 4 192.169.112.3
PING 192.169.112.3 (192.169.112.3) 56(84) bytes of data.
64 bytes from 192.169.112.3: icmp_seq=1 ttl=63 time=1.22 ms
64 bytes from 192.169.112.3: icmp_seq=2 ttl=63 time=0.726 ms
64 bytes from 192.169.112.3: icmp_seq=3 ttl=63 time=0.795 ms
64 bytes from 192.169.112.3: icmp_seq=4 ttl=63 time=0.463 ms

--- 192.169.112.3 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3004ms
rtt min/avg/max/mdev = 0.463/0.800/1.218/0.272 ms
[root@worker02 ~]#
```

Borramos uno de los pods:

```console
[kubeadmin@master first-app]$ kubectl get pods --namespace=default 
NAME                      READY   STATUS    RESTARTS   AGE
webapp-586c6d8b87-2xr5r   1/1     Running   0          4m7s
webapp-586c6d8b87-b5n5g   1/1     Running   0          10m
[kubeadmin@master first-app]$ kubectl delete pod webapp-586c6d8b87-b5n5g --namespace=default 
pod "webapp-586c6d8b87-b5n5g" deleted
[kubeadmin@master first-app]$ kubectl get pods --namespace=default -o wide
NAME                      READY   STATUS    RESTARTS   AGE     IP              NODE               NOMINATED NODE   READINESS GATES
webapp-586c6d8b87-2xr5r   1/1     Running   0          6m19s   192.169.112.4   worker01.acme.es   <none>           <none>
webapp-586c6d8b87-zggzj   1/1     Running   0          93s     192.169.112.5   worker01.acme.es   <none>           <none>
[kubeadmin@master first-app]$
```

Vemos como automáticamente kubernetes instancia un nuevo contenedor ya que el deployment indica que tiene que haber dos replicas.