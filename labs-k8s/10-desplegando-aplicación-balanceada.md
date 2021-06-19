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
/srv/nfs/weblb 192.168.168.160(rw,sync)
/srv/nfs/weblb 192.168.168.161(rw,sync)
/srv/nfs/weblb 192.168.168.162(rw,sync)
[root@kubemaster ~]# exportfs -r
[root@kubemaster ~]#
```

Copiamos el fichero [webapp-balanced](index.php) al share que hemos creado en el servidor NFS. Este fichero será servido por la aplicación balanceada.

## Almacenamiento

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