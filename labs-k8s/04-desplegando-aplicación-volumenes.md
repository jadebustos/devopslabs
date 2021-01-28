# Desplegando una aplicación con volumenes mapeados

Creamos un namespace:

```console
[kubeadmin@master webapp-volumes]$ kubectl create namespace webapp-volumes
namespace/webapp-volumes created
[kubeadmin@master webapp-volumes]$ 
```

Cuando necesitemos que un pod almacene información que no se pierda al destruirse los contenedores que contiene utilizaremos volumenes persistentes.

## Definiendo el almacenamiento

Creamos el fichero [nfs-pv.yaml](webapp-volumes/nfs-pv.yaml) para definir un persistent volume:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
  namespace: webapp-volumes
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: nfs
  mountOptions:
    - hard
    - nfsvers=4.1
  nfs:
    path: /srv/nfs
    server: 192.168.1.115
```

Previamente hemos creado un share NFS exportado a todos los nodos del clúster.

Definimos el persistent volume:

```console
[kubeadmin@master webapp-volumes]$ kubectl apply -f nfs-pv.yaml 
persistentvolume/nfs-pv created
[kubeadmin@master webapp-volumes]$ kubectl get pv --namespace=webapp-volumes
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
nfs-pv   10Gi       RWX            Recycle          Available           nfs                     55s
[kubeadmin@master webapp-volumes]$ kubectl describe pv --namespace=webapp-volumes
Name:            nfs-pv
Labels:          <none>
Annotations:     <none>
Finalizers:      [kubernetes.io/pv-protection]
StorageClass:    nfs
Status:          Available
Claim:           
Reclaim Policy:  Recycle
Access Modes:    RWX
VolumeMode:      Filesystem
Capacity:        10Gi
Node Affinity:   <none>
Message:         
Source:
    Type:      NFS (an NFS mount that lasts the lifetime of a pod)
    Server:    192.168.1.115
    Path:      /srv/nfs
    ReadOnly:  false
Events:        <none>
[kubeadmin@master webapp-volumes]
```

Para crear el **claim** y poder asignarle el volumen a un POD creamos el fichero [nfs-pvc.yaml](webapp-volumes/nfs-pvc.yaml):

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-pvc
  metadata: webapp-volumes
spec:
  storageClassName: nfs
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 2Gi
```

Hacemos el claim:

```console
[kubeadmin@master webapp-volumes]$ kubectl apply -f nfs-pvc.yaml 
persistentvolumeclaim/nfs-pvc created
[kubeadmin@master webapp-volumes]$ kubectl get pvc --namespace=webapp-volumes
NAME      STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
nfs-pvc   Bound    nfs-pv   10Gi       RWX            nfs            17s
[kubeadmin@master webapp-volumes]$ kubectl describe pvc nfs-pvc --namespace=webapp-volumes
Name:          nfs-pvc
Namespace:     webapp-volumes
StorageClass:  nfs
Status:        Bound
Volume:        nfs-pv
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      10Gi
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       <none>
Events:        <none>
[kubeadmin@master webapp-volumes]$ 
```

Al hacer el **claim** se asigna el volumen a uno o varios pods, en este aso a uno. Si se quisiera asignar otro persistent volume para otro pod kubernetes no consideraría este ya que con el claim se encuentra asignado y no esta libre.

> ![INFORMATION](../imgs/information-icon.png): [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes)

> ![INFORMATION](../imgs/information-icon.png): [NFS volume example](https://github.com/kubernetes/examples/tree/master/staging/volumes/nfs)

## Creamos el deployment

Basándonos en el de la aplicación que hemos creado anteriormente creamos el fichero yaml [webapp-volumes.yaml](webapp-volumes/webapp-volumes.yaml), incluyendo del deployment, service, ingress y el configmap:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-volumes
  namespace: webapp-volumes
  labels:
    app: webapp-volumes
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp-volumes
  template:
    metadata:
      labels:
        app: webapp-volumes
    spec:
      containers:
      - name: webapp-volumes
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
    name: volumes-service
    namespace: webapp-volumes
spec:
    selector:
      app: webapp-volumes
    ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: volumes-ingress
  namespace: webapp-volumes
  labels:
    app: webapp-volumes
  annotations:
      haproxy.org/path-rewrite: "/"
spec:
  rules:
  - host: foo-volumes.bar
    http:
      paths:
      - path: /volumes
        pathType: "Prefix"
        backend:
          service:
            name: volumes-service
            port:
              number: 80
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: haproxy-configmap
  namespace: webapp-volumes
data:
  servers-increment: "42"
  ssl-redirect: "OFF"
```

Hacemos el deployment:

```console
[kubeadmin@master webapp-volumes]$ kubectl apply -f webapp-volumes.yaml 
deployment.apps/webapp-volumes created
service/volumes-service created
ingress.networking.k8s.io/volumes-ingress created
configmap/haproxy-configmap created
[kubeadmin@master webapp-volumes]$ kubectl get pods --namespace=webapp-volumes -o wide
NAME                              READY   STATUS    RESTARTS   AGE    IP              NODE               NOMINATED NODE   READINESS GATES
webapp-volumes-5489d68846-7qxkc   1/1     Running   0          6m30s   192.169.112.9   worker01.acme.es   <none>           <none>
[kubeadmin@master webapp-volumes]$ kubectl get svc --namespace=webapp-volumes -o wide
NAME              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE     SELECTOR
volumes-service   ClusterIP   10.103.11.121   <none>        80/TCP    6m47s   app=webapp-volumes
[kubeadmin@master webapp-volumes]$ kubectl describe svc volumes-service --namespace=webapp-volumes
Name:              volumes-service
Namespace:         webapp-volumes
Labels:            <none>
Annotations:       <none>
Selector:          app=webapp-volumes
Type:              ClusterIP
IP Families:       <none>
IP:                10.103.11.121
IPs:               10.103.11.121
Port:              http  80/TCP
TargetPort:        80/TCP
Endpoints:         192.169.112.9:80
Session Affinity:  None
Events:            <none>
[kubeadmin@master webapp-volumes]$ kubectl get ep --namespace=webapp-volumes -o wide
NAME              ENDPOINTS          AGE
volumes-service   192.169.112.9:80   7m28s
[kubeadmin@master webapp-volumes]$ kubectl describe ep volumes-service --namespace=webapp-volumes 
Name:         volumes-service
Namespace:    webapp-volumes
Labels:       <none>
Annotations:  endpoints.kubernetes.io/last-change-trigger-time: 2021-01-25T08:19:26Z
Subsets:
  Addresses:          192.169.112.9
  NotReadyAddresses:  <none>
  Ports:
    Name  Port  Protocol
    ----  ----  --------
    http  80    TCP

Events:  <none>
[kubeadmin@master webapp-volumes]$ 
```

Nos conectamos al contenedor para ver que el volumen está mapeado:

```console
[kubeadmin@master webapp-volumes]$ kubectl exec --stdin --tty webapp-volumes-5489d68846-7qxkc --namespace=webapp-volumes -- /bin/bash
root@webapp-volumes-5489d68846-7qxkc:/var/www/html# ls
root@webapp-volumes-5489d68846-7qxkc:/var/www/html# df
Filesystem             1K-blocks    Used Available Use% Mounted on
overlay                 17811456 3599280  14212176  21% /
tmpfs                      65536       0     65536   0% /dev
tmpfs                    3977232       0   3977232   0% /sys/fs/cgroup
/dev/mapper/cs-root     17811456 3599280  14212176  21% /etc/hosts
shm                        65536       0     65536   0% /dev/shm
192.168.1.115:/srv/nfs  10471424  105984  10365440   2% /var/www/public
tmpfs                    3977232      12   3977220   1% /run/secrets/kubernetes.io/serviceaccount
tmpfs                    3977232       0   3977232   0% /proc/acpi
tmpfs                    3977232       0   3977232   0% /proc/scsi
tmpfs                    3977232       0   3977232   0% /sys/firmware
[root@webapp-volumes-5489d68846-7qxkc:/var/www/html# 
```

El volumen que hemos mapeado se encuentra vacío, con lo cual nos conectamos al servidor de nfs y en el directorio que tenemos compartido por nfs creamos el fichero **index.php** con el siguiente contenido:

```php
<html>
 <head>
   <title>Webapp (PHP powered)</title>
 </head>

  <body>
<?php

 echo "¡Hola mundo! <br><br>";

 $port=$_ENV["PORT"];
 echo "No importa en que puerto me busques, en realidad estoy escuchando en el puerto ".$port.".<br><br>";

 echo "Eran ";
 for($i = 1; $i < 4; $i++) {
   echo $i.", ";
 }

 echo "los tres Mosqueteros.";

?>

</body>
</html>
```

Ahora ya podemos acceder desde fuera del entorno:

```console
[jadebustos@archimedes ~]$ curl -I -H 'Host: foo-volumes.bar' 'http://192.168.1.110:30432/volumes'
HTTP/1.1 200 OK
date: Mon, 25 Jan 2021 08:07:38 GMT
server: Apache/2.4.38 (Debian)
x-powered-by: PHP/7.4.14
content-type: text/html; charset=UTF-8

[jadebustos@archimedes ~]$
```

Si no hemos borrado el ejemplo anterior podemos ver que tenemos dos aplicaciones publicadas:

```console
[kubeadmin@master webapp-volumes]$ kubectl get svc -A
NAMESPACE            NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                     AGE
calico-system        calico-typha              ClusterIP   10.111.29.122    <none>        5473/TCP                                    3h7m
default              kubernetes                ClusterIP   10.96.0.1        <none>        443/TCP                                     3h21m
haproxy-controller   haproxy-ingress           NodePort    10.103.225.131   <none>        80:30432/TCP,443:31967/TCP,1024:31588/TCP   150m
haproxy-controller   ingress-default-backend   ClusterIP   10.96.170.15     <none>        8080/TCP                                    150m
kube-system          kube-dns                  ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP                      3h21m
webapp-routed        webapp-service            ClusterIP   10.100.141.193   <none>        80/TCP                                      109m
webapp-volumes       volumes-service           ClusterIP   10.103.11.121    <none>        80/TCP                                      11m
[kubeadmin@master webapp-volumes]$ kubectl get ep -A
NAMESPACE            NAME                      ENDPOINTS                                                           AGE
calico-system        calico-typha              192.168.1.110:5473,192.168.1.111:5473,192.168.1.112:5473            3h7m
default              kubernetes                192.168.1.110:6443                                                  3h21m
haproxy-controller   haproxy-ingress           192.169.22.1:443,192.169.22.1:80,192.169.22.1:1024                  150m
haproxy-controller   ingress-default-backend   192.169.112.1:8080                                                  150m
kube-system          kube-dns                  192.169.121.68:53,192.169.121.69:53,192.169.121.68:53 + 3 more...   3h21m
webapp-routed        webapp-service            192.169.112.7:80                                                    109m
webapp-volumes       volumes-service           192.169.112.9:80                                                    11m
[kubeadmin@master webapp-volumes]$ 
```