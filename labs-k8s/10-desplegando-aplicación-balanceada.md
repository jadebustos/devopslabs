# Desplegando una apliación balanceada

Desplegaremos una aplicación balanceada.

## Namespace

Crearemos el namespace en el que se desplegará la aplicación:

```yaml
kind: Namespace
apiVersion: v1
metadata:
  name: webapp-balanced
  labels:
    name: webapp-balanced
```

## Creación de volúmenes

En el servidor NFS crearemos un share:

```console
[root@kubemaster ~]# cat /etc/exports
/srv/nfs/weblb 192.168.1.160(rw,sync)
/srv/nfs/weblb 192.168.1.161(rw,sync)
/srv/nfs/weblb 192.168.1.162(rw,sync)
[root@kubemaster ~]# exportfs -r
[root@kubemaster ~]#
```

Copiamos el fichero [webapp-balanced](index.php) al share que hemos creado en el servidor NFS. Este fichero será servido por la aplicación balanceada.

## Almacenamiento

Creamos el persistent volume y el claim:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
  namespace: webapp-balanced
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
    path: /srv/nfs/weblb
    server: 192.168.1.160
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-pvc
  namespace: webapp-balanced
spec:
  storageClassName: nfs
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 2Gi
```

## Deployment

Creamos el deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-balanced
  namespace: webapp-balanced
  labels:
    app: webapp-balanced
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp-balanced
  template:
    metadata:
      labels:
        app: webapp-balanced
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - webapp-balanced
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: webapp-balanced
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
        volumeMounts:
        - name: site-pvc
          mountPath: /var/www/public
      volumes:
      - name: site-pvc
        persistentVolumeClaim:
          claimName: nfs-pvc
```

> ![TIP](../imgs/tip-icon.png) Incluimos una regla de antiafinidad ya que queremos que cada pod se esté ejecutando en un nodo diferente para evitar que si un nodo cae nos quedemos sin servicio.

Inicialmente crearemos una única replica.

## Creamos el servicio balanceado

## Probando la aplicación balanceada

Listamos los pods:

```console
[kubeadmin@kubemaster webapp-balanced]$ kubectl get pods --namespace webapp-balanced -o wide
NAME                               READY   STATUS    RESTARTS   AGE   IP               NODE                  NOMINATED NODE   READINESS GATES
webapp-balanced-6f4f8dcd99-28s7z   1/1     Running   0          15s   192.169.45.158   kubenode2.jadbp.lab   <none>           <none>
[kubeadmin@kubemaster webapp-balanced]$ 
```

La ip expuesta para conexiones:

```console
[kubeadmin@kubemaster webapp-balanced]$ kubectl get svc --namespace haproxy-controller
NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                     AGE
haproxy-ingress           NodePort    10.102.13.90     <none>        80:31716/TCP,443:32613/TCP,1024:32192/TCP   11d
ingress-default-backend   ClusterIP   10.110.195.119   <none>        8080/TCP                                    11d
[kubeadmin@kubemaster webapp-balanced]$ 
```

Si nos conectamos a la aplicación:

![IMG](../imgs/webapp-balanced-1.png)

Si recargamos la página podremos ver que la ip no cambia. Tenemos un único pod sirviendo la aplicación.

Escalamos el deployment para tener dos pods:

```console
[kubeadmin@kubemaster labs-k8s]$ kubectl scale --replicas=2 deployment/webapp-balanced --namespace=webapp-balanced
deployment.apps/webapp-balanced scaled
[kubeadmin@kubemaster webapp-balanced]$ kubectl get pods --namespace webapp-balanced -o wide
NAME                               READY   STATUS    RESTARTS   AGE   IP               NODE                  NOMINATED NODE   READINESS GATES
webapp-balanced-6f4f8dcd99-28s7z   1/1     Running   0          38s   192.169.45.158   kubenode2.jadbp.lab   <none>           <none>
webapp-balanced-6f4f8dcd99-tl9xn   1/1     Running   0          11s   192.169.62.36    kubenode1.jadbp.lab   <none>           <none>
[kubeadmin@kubemaster webapp-balanced]$
```

Vemos que los pods se están ejecutando en nodos diferentes, tal y como configuramos el deployment con las reglas de antiafinidad. Si recargamos la página del navegador:

![IMG](../imgs/webapp-balanced-2.png)

Podemos ir recargando y veremos que cada vez que recargamos se muestra una ip diferente. Cada petición la está sirviendo un pod diferente.
