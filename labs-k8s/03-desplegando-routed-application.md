# Desplegando la primera aplicación accesible desde el exterior

## Definimos el deployment para la aplicación

Junto con el deployment definimos un servicio en el fichero [first-routed-webapp.yaml](first-routed-webapp/first-routed-webapp.yaml):

```yaml

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-routed
  namespace: webapp-routed
  labels:
    app: webapp-routed
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp-routed
  template:
    metadata:
      labels:
        app: webapp-routed
    spec:
      containers:
      - name: webapp-routed
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
    name: webapp-service
    namespace: webapp-routed
spec:
    selector:
      app: webapp-routed
    ports:
    - name: http
      protocol: TCP
      port: 80 # puerto en el que escucha el servicio
      targetPort: 80 # puerto en el que escucha el contenedor
```

## Desplegamos la aplicación

Creamos un namespace y desplegamos la aplicación:

```console
[kubeadmin@kubemaster first-routed-app]$ kubectl create namespace webapp-routed
namespace/webapp-routed created
[kubeadmin@kubemaster first-routed-app]$ kubectl apply -f first-routed-webapp.yaml
deployment.apps/webapp-routed created
service/webapp-service created
[kubeadmin@kubemaster first-routed-app]$ kubectl get pods --namespace=webapp-routed -o wide
NAME                             READY   STATUS    RESTARTS   AGE   IP              NODE                NOMINATED NODE   READINESS GATES
webapp-routed-54b7b66f9b-6zb9r   1/1     Running   0          12s   192.169.232.4   kubenode1.acme.es   <none>           <none>
[kubeadmin@kubemaster first-routed-app]$ kubectl get svc --namespace=webapp-routed -o wide
NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE   SELECTOR
webapp-service   ClusterIP   10.109.18.232   <none>        80/TCP    33s   app=webapp-routed
[kubeadmin@kubemaster first-routed-app]$ kubectl describe svc webapp-service --namespace=webapp-routed
Name:              webapp-service
Namespace:         webapp-routed
Labels:            <none>
Annotations:       <none>
Selector:          app=webapp-routed
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.109.18.232
IPs:               10.109.18.232
Port:              http  80/TCP
TargetPort:        80/TCP
Endpoints:         192.169.232.4:80
Session Affinity:  None
Events:            <none>
[kubeadmin@kubemaster first-routed-app]$ 
```

## Creamos el ingress

Creamos el fichero [ingress.yaml](first-routed-webapp/ingress.yaml):

```yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  namespace: webapp-routed
  labels:
    app: webapp-routed
  annotations:
      haproxy.org/path-rewrite: "/"
spec:
  rules:
  - host: foo.bar
    http:
      paths:
      - path: /webapp-routed
        pathType: "Prefix"
        backend:
          service:
            name: webapp-service
            port:
              number: 80
```

Desplegamos el ingress:

```console
[kubeadmin@kubemaster first-routed-app]$ kubectl apply -f ingress.yaml
ingress.networking.k8s.io/webapp-ingress created
[kubeadmin@kubemaster first-routed-app]$ kubectl get ingress --namespace=webapp-routed
NAME             CLASS    HOSTS     ADDRESS   PORTS   AGE
webapp-ingress   <none>   foo.bar             80      12s
[kubeadmin@kubemaster first-routed-app]$ kubectl describe ingress webapp-ingress --namespace=webapp-routed
Name:             webapp-ingress
Labels:           app=webapp-routed
Namespace:        webapp-routed
Address:          
Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
Rules:
  Host        Path  Backends
  ----        ----  --------
  foo.bar     
              /webapp-routed   webapp-service:80 (192.169.232.4:80)
Annotations:  haproxy.org/path-rewrite: /
Events:       <none>

[kubeadmin@kubemaster first-routed-app]$
```

Comprobamos el endpoint:

```console
[kubeadmin@kubemaster first-routed-app]$ kubectl get ep --namespace=webapp-routed
NAME             ENDPOINTS          AGE
webapp-service   192.169.232.4:80   2m19s
[kubeadmin@kubemaster first-routed-app]$ kubectl describe ep webapp-service --namespace=webapp-routed
Name:         webapp-service
Namespace:    webapp-routed
Labels:       <none>
Annotations:  endpoints.kubernetes.io/last-change-trigger-time: 2022-02-13T23:38:47Z
Subsets:
  Addresses:          192.169.232.4
  NotReadyAddresses:  <none>
  Ports:
    Name  Port  Protocol
    ----  ----  --------
    http  80    TCP

Events:  <none>
[kubeadmin@kubemaster first-routed-app]$ 
```

Definimos un ConfigMap en el fichero [configmap.yaml](first-routed-webapp/configmap.yaml):

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: haproxy-configmap
  namespace: webapp-routed
data:
  servers-increment: "42"
  ssl-redirect: "OFF"
```

```console
[kubeadmin@kubemaster first-routed-app]$ kubectl apply -f configmap.yaml 
configmap/haproxy-configmap created
[kubeadmin@kubemaster first-routed-app]$ 
```

Aunque apenas hemos incluido configuración en este ConfigMap podemos incluir [configuración](https://github.com/haproxytech/kubernetes-ingress/tree/master/documentation) adicional, como configuración de certificados si utilizamos TLS, ...

Comprobamos que es accesible desde fuera:

```console
[kubeadmin@kubemaster first-routed-webapp]$ kubectl get svc --namespace=haproxy-controller
NAME                                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                     AGE
haproxy-kubernetes-ingress                   NodePort    10.104.187.186   <none>        80:31826/TCP,443:30886/TCP,1024:31734/TCP   69m
haproxy-kubernetes-ingress-default-backend   ClusterIP   10.103.195.4     <none>        8080/TCP                                    69m
[kubeadmin@kubemaster first-routed-webapp]$ 
```

Tenemos que el puerto **31826** del master se encuentra mapeado al **80** de los contenedores, luego si desde una máquina que no sea el master hacemos:

```console
[jadebustos@archimedes ~]$ curl -I -H 'Host: foo.bar' 'http://192.168.1.110:31826/webapp-routed'
HTTP/1.1 200 OK
date: Sun, 13 Feb 2022 23:43:13 GMT
server: Apache/2.4.38 (Debian)
x-powered-by: PHP/7.4.20
content-type: text/html; charset=UTF-8

[jadebustos@archimedes ~]$
```

Como obtenemos un código **HTTP/1.1 200 OK** ya estaría accesible desde el exterior.

Si hacemos resolver **foo.bar** a la dirección ip del mater **192.168.1.110** podremos acceder a nuestra aplicación accediendo a **http://<span></span>foo.bar:31826/webapp**.

> ![INFORMATION](../imgs/information-icon.png) [Service](https://kubernetes.io/docs/concepts/services-networking/service/)

> ![INFORMATION](../imgs/information-icon.png) [HAproxy Ingress](https://www.haproxy.com/documentation/kubernetes/latest/)

> ![INFORMATION](../imgs/information-icon.png) [Dissecting the haproxy kubernetes ingress controller](https://www.haproxy.com/blog/dissecting-the-haproxy-kubernetes-ingress-controller/)

## Como funciona el Ingress

El ingress controller se encarga de enrutar el tráfico, nos conectamos al ingress controller:

```console
[kubeadmin@kubemaster ~]$ kubectl get pods -A -o wide | grep haproxy
haproxy-controller   haproxy-kubernetes-ingress-54f9b477b9-tnq4r                   1/1     Running   0          70m     192.169.49.66   kubenode2.acme.es    <none>           <none>
haproxy-controller   haproxy-kubernetes-ingress-default-backend-6b7ddb86b9-qztwc   1/1     Running   0          70m     192.169.49.65   kubenode2.acme.es    <none>           <none>
[kubeadmin@kubemaster ~]$ kubectl exec --stdin --tty haproxy-kubernetes-ingress-54f9b477b9-tnq4r --namespace=haproxy-controller -- /bin/sh
Defaulted container "haproxy-ingress" out of: haproxy-ingress, sysctl (init)
/ $ 
```

Veamos la configuración del **haproxy**:

```console
/ $ cd /etc/haproxy/
/usr/local/etc/haproxy $ ls -lh
total 8K     
drwxr-xr-x    5 haproxy  haproxy       47 Feb 13 22:33 certs
-rwxrwxr--    1 haproxy  haproxy        0 Jan 11 11:22 dataplaneapi.hcl
drwxr-xr-x    2 haproxy  haproxy        6 Feb 13 22:33 errorfiles
drwxrwxr-x    1 root     haproxy      132 Jan 11 11:22 errors
-rw-rw-r--    1 haproxy  haproxy        0 Feb 13 22:33 haproxy-aux.cfg
-rw-r--r--    1 haproxy  haproxy     7.3K Feb 13 23:40 haproxy.cfg
drwxr-xr-x    2 haproxy  haproxy       82 Feb 13 22:33 maps
drwxr-xr-x    2 haproxy  haproxy        6 Feb 13 22:33 patterns
```

Dentro del fichero **haproxy.cfg** tendremos la siguiente configuración:

```
backend webapp-routed-webapp-service-http
  mode http                           
  balance roundrobin                                           
  option forwardfor                                                                 
  no option abortonclose                                                                                                                     
  default-server check                                                                                             
  server SRV_1 192.169.232.4:80 enabled                                                                                                                      
  server SRV_2 127.0.0.1:80 disabled         
...
  server SRV_40 127.0.0.1:80 disabled                              
  server SRV_41 127.0.0.1:80 disabled  
  server SRV_42 127.0.0.1:80 disabled
```

Esta redireccionando las peticiones hacía la dirección del endpoint definido en el ingress que creamos para la aplicación:

```console
[kubeadmin@kubemaster ~]$ kubectl get ep webapp-service --namespace=webapp-routed
NAME             ENDPOINTS          AGE
webapp-service   192.169.232.4:80   8m6s
[kubeadmin@kubemaster ~]$ kubectl describe ep webapp-service --namespace=webapp-routed
Name:         webapp-service
Namespace:    webapp-routed
Labels:       <none>
Annotations:  endpoints.kubernetes.io/last-change-trigger-time: 2022-02-13T23:38:47Z
Subsets:
  Addresses:          192.169.232.4
  NotReadyAddresses:  <none>
  Ports:
    Name  Port  Protocol
    ----  ----  --------
    http  80    TCP

Events:  <none>

[kubeadmin@kubemaster ~]$  
```

![ingress](../imgs/kubernetes-networking.png)