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

Inicialmente crearemos una única replica.