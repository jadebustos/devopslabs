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
webapp-6857ff4857-ngxfx   1/1     Running   0          2m55s
[kubeadmin@kubemaster first-app]$ kubectl describe pod webapp-6857ff4857-ngxfx --namespace=first-app
Name:         webapp-6857ff4857-ngxfx
Namespace:    first-app
Priority:     0
Node:         kubenode1.jadbp.lab/192.168.1.161
Start Time:   Fri, 28 Jan 2022 16:12:59 +0100
Labels:       app=webapp
              pod-template-hash=6857ff4857
Annotations:  cni.projectcalico.org/containerID: cbffa61fcec1889b45a81123c6d8cd63a4bffaa3873f92a7e92ccd0d29004a50
              cni.projectcalico.org/podIP: 192.169.62.3/32
              cni.projectcalico.org/podIPs: 192.169.62.3/32
Status:       Running
IP:           192.169.62.3
IPs:
  IP:           192.169.62.3
Controlled By:  ReplicaSet/webapp-6857ff4857
Containers:
  webapp:
    Container ID:   cri-o://12daab13b1a724305df3e2a661af8149a9b066039465619bda9d114d7499dda1
    Image:          quay.io/rhte_2019/webapp:v1
    Image ID:       quay.io/rhte_2019/webapp@sha256:d51ff7792bdd9a6e70b6e151adf47f357e6fd6830fceaf403f7c66e34ed367b2
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Fri, 28 Jan 2022 16:13:00 +0100
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-7z786 (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  kube-api-access-7z786:
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
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  3m34s  default-scheduler  Successfully assigned first-app/webapp-6857ff4857-ngxfx to kubenode1.jadbp.lab
  Normal  Pulled     3m33s  kubelet            Container image "quay.io/rhte_2019/webapp:v1" already present on machine
  Normal  Created    3m33s  kubelet            Created container webapp
  Normal  Started    3m33s  kubelet            Started container webapp
[kubeadmin@kubemaster first-app]$ 
```

Podemos ver los eventos del namespace para ver que está pasando:

```console
[kubeadmin@kubemaster first-app]$ kubectl get events --namespace=first-app
LAST SEEN   TYPE     REASON              OBJECT                         MESSAGE
...
4m20s       Normal   Scheduled           pod/webapp-6857ff4857-ngxfx    Successfully assigned first-app/webapp-6857ff4857-ngxfx to kubenode1.jadbp.lab
4m19s       Normal   Pulled              pod/webapp-6857ff4857-ngxfx    Container image "quay.io/rhte_2019/webapp:v1" already present on machine
4m19s       Normal   Created             pod/webapp-6857ff4857-ngxfx    Created container webapp
4m19s       Normal   Started             pod/webapp-6857ff4857-ngxfx    Started container webapp
4m20s       Normal   SuccessfulCreate    replicaset/webapp-6857ff4857   Created pod: webapp-6857ff4857-ngxfx
4m21s       Normal   ScalingReplicaSet   deployment/webapp              Scaled up replica set webapp-6857ff4857 to 1

...
[kubeadmin@kubemaster first-app]$ 
```

Podemos consultar el yaml del pod:

```console
[kubeadmin@kubemaster first-app]$ kubectl get pod webapp-6857ff4857-ngxfx -o yaml > webapp-6857ff4857-ngxfx.yaml
```
> ![HOMEWORK](../imgs/homework-icon.png) Probar con **-o json**.

## Borrando objetos en kubernetes

Podemos borrar el pod:

```console
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app
NAME                      READY   STATUS    RESTARTS   AGE
webapp-6857ff4857-ngxfx   1/1     Running   0          5m54s
[kubeadmin@kubemaster first-app]$ kubectl delete pods webapp-6857ff4857-ngxfx --namespace=first-app
pod "webapp-6857ff4857-ngxfx" deleted
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app
NAME                      READY   STATUS    RESTARTS   AGE
webapp-6857ff4857-4d8n7   1/1     Running   0          40s
[kubeadmin@kubemaster first-app]$ 
```

Vemos que existe todavía, pero si nos fijamos tiene un nombre diferente:

```console
[kubeadmin@kubemaster first-app]$ kubectl get events --namespace=first-app
LAST SEEN   TYPE     REASON             OBJECT                         MESSAGE
...
76s         Normal   Scheduled           pod/webapp-6857ff4857-4d8n7    Successfully assigned first-app/webapp-6857ff4857-4d8n7 to kubenode1.jadbp.lab
75s         Normal   Pulled              pod/webapp-6857ff4857-4d8n7    Container image "quay.io/rhte_2019/webapp:v1" already present on machine
75s         Normal   Created             pod/webapp-6857ff4857-4d8n7    Created container webapp
75s         Normal   Started             pod/webapp-6857ff4857-4d8n7    Started container webapp
7m49s       Normal   Scheduled           pod/webapp-6857ff4857-ngxfx    Successfully assigned first-app/webapp-6857ff4857-ngxfx to kubenode1.jadbp.lab
7m48s       Normal   Pulled              pod/webapp-6857ff4857-ngxfx    Container image "quay.io/rhte_2019/webapp:v1" already present on machine
7m48s       Normal   Created             pod/webapp-6857ff4857-ngxfx    Created container webapp
7m48s       Normal   Started             pod/webapp-6857ff4857-ngxfx    Started container webapp
76s         Normal   Killing             pod/webapp-6857ff4857-ngxfx    Stopping container webapp
7m49s       Normal   SuccessfulCreate    replicaset/webapp-6857ff4857   Created pod: webapp-6857ff4857-ngxfx
76s         Normal   SuccessfulCreate    replicaset/webapp-6857ff4857   Created pod: webapp-6857ff4857-4d8n7
7m50s       Normal   ScalingReplicaSet   deployment/webapp              Scaled up replica set webapp-6857ff4857 to 1
...
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
webapp   1/1     1            1           8m44s
[kubeadmin@kubemaster first-app]$ kubectl delete deployments webapp --namespace=first-app
deployment.apps "webapp" deleted
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app
NAME                      READY   STATUS        RESTARTS   AGE
webapp-68965f4fcc-vfgsnwebapp-586c6d8b87-b5n5g
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app
NAME                      READY   STATUS        RESTARTS   AGE
webapp-6857ff4857-4d8n7   1/1     Terminating   0          2m48s
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app
No resources found in first-app namespace.
[kubeadmin@kubemaster first-app]$ 
```

## Escalando un deployment

Para escalar un deployment:

```console
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app
NAME                      READY   STATUS    RESTARTS   AGE
webapp-6857ff4857-8qt9d   1/1     Running   0          5m10s
[kubeadmin@kubemaster first-app]$ kubectl get deployments --namespace=first-app
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
webapp   1/1     1            1           5m29s
[kubeadmin@kubemaster first-app]$ kubectl edit deployment webapp --namespace=first-app
```

> ![TIP](imgs/tip-icon.png) Si borraste el deployment en el paso anterior tendrás que volver a desplegarlo.

Editará el deployment en el editor por defecto. Iremos a las especificaciones y en el campo **replica** especificaremos cuantas replicas queremos:

```yaml
spec:
  progressDeadlineSeconds: 600
  replicas: 2
```

Guardamos los cambios y salimos:

```console
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app
NAME                      READY   STATUS    RESTARTS   AGE
webapp-6857ff4857-48rvj   1/1     Running   0          36s
webapp-6857ff4857-8qt9d   1/1     Running   0          7m13s
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app -o wide
NAME                      READY   STATUS    RESTARTS   AGE     IP               NODE                  NOMINATED NODE   READINESS GATES
webapp-6857ff4857-48rvj   1/1     Running   0          61s     192.169.45.129   kubenode2.jadbp.lab   <none>           <none>
webapp-6857ff4857-8qt9d   1/1     Running   0          7m38s   192.169.62.5     kubenode1.jadbp.lab   <none>           <none>
[kubeadmin@kubemaster first-app]$ 
```

Como ambos contenedores se están ejecutando en diferentes workers vamos a uno de ellos y hacemos un ping a sus ips:

```console
[root@kubenode1 ~]# ping -c 4 192.169.45.129
PING 192.169.45.129 (192.169.45.129) 56(84) bytes of data.
64 bytes from 192.169.45.129: icmp_seq=1 ttl=63 time=0.630 ms
64 bytes from 192.169.45.129: icmp_seq=2 ttl=63 time=0.532 ms
64 bytes from 192.169.45.129: icmp_seq=3 ttl=63 time=0.678 ms
64 bytes from 192.169.45.129: icmp_seq=4 ttl=63 time=0.450 ms

--- 192.169.45.129 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3106ms
rtt min/avg/max/mdev = 0.450/0.572/0.678/0.091 ms
[root@kubenode1 ~]# ping -c 4 192.169.62.5
PING 192.169.62.5 (192.169.62.5) 56(84) bytes of data.
64 bytes from 192.169.62.5: icmp_seq=1 ttl=64 time=0.111 ms
64 bytes from 192.169.62.5: icmp_seq=2 ttl=64 time=0.082 ms
64 bytes from 192.169.62.5: icmp_seq=3 ttl=64 time=0.087 ms
64 bytes from 192.169.62.5: icmp_seq=4 ttl=64 time=0.098 ms

--- 192.169.62.5 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3051ms
rtt min/avg/max/mdev = 0.082/0.094/0.111/0.014 ms
[root@kubenode1 ~]#
```

Borramos uno de los pods:

```console
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app 
NAME                      READY   STATUS    RESTARTS   AGE
webapp-6857ff4857-48rvj   1/1     Running   0          5m26s
webapp-6857ff4857-8qt9d   1/1     Running   0          12m
[kubeadmin@kubemaster first-app]$ kubectl delete pod webapp-6857ff4857-48rvj --namespace=first-app
pod "webapp-6857ff4857-48rvj" deleted
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=first-app -o wide
NAME                      READY   STATUS    RESTARTS   AGE   IP               NODE                  NOMINATED NODE   READINESS GATES
webapp-6857ff4857-8qt9d   1/1     Running   0          13m   192.169.62.5     kubenode1.jadbp.lab   <none>           <none>
webapp-6857ff4857-j6pjt   1/1     Running   0          34s   192.169.45.130   kubenode2.jadbp.lab   <none>           <none>
[kubeadmin@kubemaster first-app]$
```

Vemos como automáticamente kubernetes instancia un nuevo contenedor ya que el deployment indica que tiene que haber dos replicas.