# Desplegando aplicaciones que no utilizan tráfico HTTP (WIP)

Las aplicaciones que hemos visto hasta ahora utilizan el protocolo HTTP(s), es decir son aplicaciones web.

Pero no todas las aplicaciones que queramos desplegar serán de este tipo. Puede que, en determinadas, circunstancias necesitemos dar acceso desde el exterior a una bbdd que se esté ejecutando dentro de kubernetes.

Ingress se encarga de [publicar rutas HTTP y HTTPS](https://kubernetes.io/docs/concepts/services-networking/ingress/) hacía servicios dentro de kubernetes. Por este motivo si necesitamos proporcionar acceso a aplicaciones que no hablan HTTP o HTTPS no podremos utilizar el ingress controller.

## Seleccionando una aplicación no HTTP/HTTPS

Vamos a desplegar una base de datos PostgreSQL en kubernetes y a proporcionarle acceso desde fuera de kubernetes.

Para ello buscaremos una imagen de PostgreSQL. Utilizaremos la [imagen oficial de PostgreSQL que se encuentra publicada en Dockerhub](https://hub.docker.com/_/postgres).

Será necesario leer la información facilitada de donde obtendremos la siguiente información:

* Es necesario pasar una variable de entorno **POSTGRES_PASSWORD** con el password que queramos utilizar para el acceso a la base de datos. Hemos elegido como contraseña **temporal**.
* Si no se especifica un nombre de usuario el usuario por defecto es **postgres**.

> ![HOMEWORK](../imgs/homework-icon.png) Se pueden parametrizar varios parámetros.

## Desplegando la aplicación

Para desplegar la aplicación crearemos un deployment y le pasaremos, al menos, la variable **POSTGRES_PASSWORD**:

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: postgres
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: postgres
  labels:
    app: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres
        env:
        - name: POSTGRES_PASSWORD
          value: "temporal"
        ports:
        - containerPort: 5432
---
apiVersion: v1
kind: Service
metadata:
    name: postgres-service
    namespace: postgres
spec:
    type: NodePort
    selector:
      app: postgres
    ports:
    - nodePort: 31234
      port: 5432
      targetPort: 5432
```

Como ya hemos comentado no vamos a utilizar un ingress para el acceso ya que el tráfico que necesita PostgreSQL no es del tipo HTTP/HTTPS.

Por este motivo definiremos el servicio de la siguiente manera:

```yaml
---
apiVersion: v1
kind: Service
metadata:
    name: postgres-service
    namespace: postgres
spec:
    type: NodePort
    selector:
      app: postgres
    ports:
    - nodePort: 31234
      port: 5432
      targetPort: 5432
```

Ahora hemos definido el servicio de tipo **NodePort**. En los anteriores ejemplos se había dejado al valor por defecto que es **ClusterIP**
