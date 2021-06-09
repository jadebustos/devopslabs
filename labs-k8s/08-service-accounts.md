# Service Accounts

Las service account son cuentas que se utilizan para ejecutar pods y permiten establecer mecanismos para identificar a los pods y permitir el acceso a determinados recursos.

Aunque no hemos utilizado, todavía, service accounts cuando hemos desplegado aplicaciones se despliegan utilizando la service account por defecto del namespace en el que desplegamos la aplicación. Si sacamos la descripción de un pod cualquiera que tengamos desplegado:

```console
[kubeadmin@master webapp-sa]$ kubectl get pod webapp-7469c9f8d6-ncqtp --namespace webapp -o yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    cni.projectcalico.org/podIP: 192.169.62.12/32
    cni.projectcalico.org/podIPs: 192.169.62.12/32
  creationTimestamp: "2021-06-08T21:44:28Z"
  generateName: webapp-7469c9f8d6-
  labels:
    app: webapp
    pod-template-hash: 7469c9f8d6
  name: webapp-7469c9f8d6-ncqtp
  namespace: webapp
  ownerReferences:
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: ReplicaSet
    name: webapp-7469c9f8d6
    uid: 7ccae4d4-cc82-4af7-b801-47f4626f43a6
  resourceVersion: "11716"
  uid: de7a377c-21bb-498d-a1b7-45057b8d2bdd
spec:
  containers:
  - image: docker.io/jadebustos2/pruebas:latest
    imagePullPolicy: Always
    name: webapp
    ports:
    - containerPort: 80
      protocol: TCP
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-2rckc
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: kubenode1.jadbp.lab
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: kube-api-access-2rckc
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2021-06-08T21:44:28Z"
    status: "True"
    type: Initialized
  - lastProbeTime: null
    lastTransitionTime: "2021-06-08T21:44:32Z"
    status: "True"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: "2021-06-08T21:44:32Z"
    status: "True"
    type: ContainersReady
  - lastProbeTime: null
    lastTransitionTime: "2021-06-08T21:44:28Z"
    status: "True"
    type: PodScheduled
  containerStatuses:
  - containerID: docker://74c690ebe01394a29ef2ef91d4d22bc3fe66880355a47f51a7dff6239a506454
    image: jadebustos2/pruebas:latest
    imageID: docker-pullable://jadebustos2/pruebas@sha256:9b44d8ac51d1ba58a4b10b19115254d95c3d91d35e6560abd0d56fa85bc663c5
    lastState: {}
    name: webapp
    ready: true
    restartCount: 0
    started: true
    state:
      running:
        startedAt: "2021-06-08T21:44:32Z"
  hostIP: 192.168.1.161
  phase: Running
  podIP: 192.169.62.12
  podIPs:
  - ip: 192.169.62.12
  qosClass: BestEffort
  startTime: "2021-06-08T21:44:28Z"
[kubeadmin@master webapp-sa]$
```

Podemos ver lo siguiente en la salida anterior:

```yaml
  serviceAccount: default
  serviceAccountName: default
```

Como no se ha especificado una service account se ejecuta con la service account por defecto del namespace, **default**.

> ![NOTE](../imgs/note-icon.png) Con **kubectl get pods -A** podemos ver todos los pods ejecutándose. Es interesantes realizar la anterior operación para los pods desplegados por kubernetes, la SDN o el ingress controller y comprobar a ver bajo que service accounts han sido desplegados.

## User accounts y service accounts

Las cuentas de usuario o user accounts son globales al clúster y por lo tanto  tienen que tener nombres diferentes. Además, normalmente, se suelen almacenar en sistemas externos, IdPs o Identity Providers, como servidores LDAP, Active Directory, ...

## Creando una service account

Vamos a crear una service account en un namespace:

```console
[kubeadmin@master webapp-sa]$ kubectl create namespace webapp-sa
namespace/webapp-sa created
[kubeadmin@master webapp-sa]$ kubectl apply -f service-account.yaml 
serviceaccount/demo-sa created
[kubeadmin@master webapp-sa]$
```

Donde [service-account.yaml](webapp-sa/service-account.yaml):

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
 name: webapp-sa
 namespace: webapp-sa
```

Podemos ver las service-account asociadas a un namespace y obtener información sobre ellas:

```console
[kubeadmin@master webapp-sa]$ kubectl get sa --namespace webapp-sa 
NAME        SECRETS   AGE
default     1         6m3s
webapp-sa   1         41s
[kubeadmin@master webapp-sa]$ kubectl describe sa webapp-sa --namespace webapp-sa 
Name:                webapp-sa
Namespace:           webapp-sa
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   webapp-sa-token-mfdcj
Tokens:              webapp-sa-token-mfdcj
Events:              <none>
[kubeadmin@master webapp-sa]$ 
```

Las service accounts son objetos de kubernetes y se definen dentro de los namespaces, por lo tanto son locales al namespace.

Tal y como la hemos creado la service account no es útil, será necesario asociarle una serie de privilegios. Estos privilegios en kubernetes se les conoce como **Role** y **ClusterRole**.

## Roles y ClusterRole en kubernetes

**Role** aplica a un namespace, mientras que **ClusterRole** aplica a todo el clúster.

Tanto **Role** como **ClusterRole** contiene una serie de reglas que definen lo que se puede hacer en su ámbito (namespace o clúster).

Esto se indica de la siguiente manera:

+ Se indica que acciones se pueden realizar (**list**, **get**, ...).
+ Contra que recursos se pueden utilizar (**pods**, **services**, ...).
+ Contra que endpoints del API se pueden lanzar ([API groups](https://kubernetes.io/docs/reference/using-api/).) Los [API groups disponibles](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.21/#-strong-api-groups-strong-).

Para definir un role:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: list-pods
  namespace: webapp-sa
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

Este role se define en el namespace **default** y permite ejecutar las acciones **get**, **watch** y **list** para los **pods**.

Los API groups permiten extender el API de kubernetes. Son un PATH en el API rest, al que se podrá atacar si se garantiza acceso en el **Role** o **ClusterRole**. En los ficheros YAML que se utilizan en kubernetes los API groups se definen en el campo **apiVersion**.

> ![INFORMATION](../imgs/information-icon.png) [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) ofrece más información y ejemplos de **ClusterRole**.

Una vez que tenemos definido un **Role** (o un **ClusterRole**) será necesario asociarlo a una service account (o a un usuario). Para ello utilizaremos **RoleBinding** para un **Role** o **ClusterRoleBinding** para un **ClusterRole**:

```yaml
kind: RoleBinding
# You need to already have a Role named "list-pods" in that namespace.
apiVersion: rbac.authorization.k8s.io/v1
metadata:
   name: webapp-sa-list-pods
   namespace: webapp-sa
subjects:
 - kind: ServiceAccount
   name: webapp-sa
   namespace: webapp-sa
roleRef:
   kind: Role # this must be Role or ClusterRole
   name: list-pods # this must match the name of the Role or ClusterRole you wish to bind to
   apiGroup: rbac.authorization.k8s.io
```

La service account **webapp-sa** será capaz de listar los pods del namespace **webapp-sa**.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-sa
  namespace: webapp-sa
  labels:
    app: webapp-sa
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp-sa
  template:
    metadata:
      labels:
        app: webapp-sa
    spec:
      serviceAccountName: webapp-sa
      containers:
      - name: alpine
        image: "alpine:latest"
        command:
        - "sleep"
        - "3600"
```

Creamos el **role**, hacemos el **rolebinding** y hacemos un deployment:

```console
[kubeadmin@master webapp-sa]$kubectl apply -f role.yaml 
role.rbac.authorization.k8s.io/list-pods created
[kubeadmin@master webapp-sa]$ kubectl apply -f rolebinding.yaml 
rolebinding.rbac.authorization.k8s.io/webapp-sa-list-pods created
[kubeadmin@master webapp-sa]$ kubectl apply -f deployment-sa.yaml 
deployment.apps/pod-example-sa created
[kubeadmin@master webapp-sa]$
```

El deployment ejecutará el comando **sleep 3600** con lo cual nos dará tiempo a lanzar una shell en el contenedor, instalaremos el paquete **curl**. En el ejemplo veremos como acceder al token de la **service account** y utilizarlo para listar los pods del namespace **default**, que dará error, y los del namespace donde hemos definido la **service account**:

```console
[kubeadmin@kubemaster webapp-sa]$ kubectl exec --stdin --tty webapp-sa-55466bf44-dlqn5 --namespace=webapp-sa -- /bin/ash
/ # apk add curl
fetch https://dl-cdn.alpinelinux.org/alpine/v3.13/main/x86_64/APKINDEX.tar.gz
fetch https://dl-cdn.alpinelinux.org/alpine/v3.13/community/x86_64/APKINDEX.tar.gz
(1/5) Installing ca-certificates (20191127-r5)
(2/5) Installing brotli-libs (1.0.9-r3)
(3/5) Installing nghttp2-libs (1.42.0-r1)
(4/5) Installing libcurl (7.77.0-r0)
(5/5) Installing curl (7.77.0-r0)
Executing busybox-1.32.1-r6.trigger
Executing ca-certificates-20191127-r5.trigger
OK: 8 MiB in 19 packages
/ # TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
/ # echo $TOKEN
eyJhbGciOiJSUzI1NiIsImtpZCI6InlaX1ZEVjZyeVJCeEJqeXR3d190Y2lrekE5c1liY0JTY0dsUi13X1dnVVUifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNjU0ODEzNjAwLCJpYXQiOjE2MjMyNzc2MDAsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJ3ZWJhcHAtc2EiLCJwb2QiOnsibmFtZSI6IndlYmFwcC1zYS01NTQ2NmJmNDQtZGxxbjUiLCJ1aWQiOiIzOTA1MTk2ZC04Y2U2LTQyMzMtODRjZi0xNDVhOTIyNTU3OGEifSwic2VydmljZWFjY291bnQiOnsibmFtZSI6IndlYmFwcC1zYSIsInVpZCI6IjdlNGJhNjI2LTljYTAtNDM2ZC05OGFjLTYxZjUxYTY0NmIwZCJ9LCJ3YXJuYWZ0ZXIiOjE2MjMyODEyMDd9LCJuYmYiOjE2MjMyNzc2MDAsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDp3ZWJhcHAtc2E6d2ViYXBwLXNhIn0.DuEfILK25QGnN1C8_dJm4kEC2uCvE7J_MR89iSTSWeXwxcYV_eGn6S4JrfgO2-wHgj79DBe9V6XVLniTF6aKL6pAquKL0gnzCr7ffmVA2GNQOoUOJsUVyki2u3UOiLtLn6IjLIC2e1I5CMUgG_4vJ8gCLAeSSPWiessbGviwLx14LpnQlfN6VUTyucNx7jes2J7x04yd9ePF8Bqdo-FLfVuqJq9z-ZB-s_Y06_X_55wDcUon_1DOt3esiLuUK0i-13PO1eaE8PNyYjr0z_0cTOSH7B_BKe4-s5HN8ocMJAU4GyjO8lZLfs8NoHM6Z9AmHT0_0OGQjp8pSsy7UNaHOQ
/ # curl -H "Authorization: Bearer $TOKEN" https://192.168.1.160/api/v1/namespaces/default/pods/ --insecure
curl: (7) Failed to connect to 192.168.1.160 port 443: Connection refused
/ # curl -H "Authorization: Bearer $TOKEN" https://192.168.1.160:6443/api/v1/namespaces/default/pods/ --insecure
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {
    
  },
  "status": "Failure",
  "message": "pods is forbidden: User \"system:serviceaccount:webapp-sa:webapp-sa\" cannot list resource \"pods\" in API group \"\" in the namespace \"default\"",
  "reason": "Forbidden",
  "details": {
    "kind": "pods"
  },
  "code": 403
/ # curl -H "Authorization: Bearer $TOKEN" https://192.168.1.160:6443/api/v1/namespaces/webapp-sa/pods/ --insecure
{
  "kind": "PodList",
  "apiVersion": "v1",
  "metadata": {
    "resourceVersion": "31725"
  },
  "items": [
    {
      "metadata": {
        "name": "webapp-sa-55466bf44-dlqn5",
        "generateName": "webapp-sa-55466bf44-",
        "namespace": "webapp-sa",
        "uid": "3905196d-8ce6-4233-84cf-145a9225578a",
        "resourceVersion": "30188",
        "creationTimestamp": "2021-06-09T22:26:40Z",
        "labels": {
          "app": "webapp-sa",
          "pod-template-hash": "55466bf44"
        },
        "annotations": {
          "cni.projectcalico.org/podIP": "192.169.62.21/32",
          "cni.projectcalico.org/podIPs": "192.169.62.21/32"
        },
        "ownerReferences": [
          {
            "apiVersion": "apps/v1",
            "kind": "ReplicaSet",
            "name": "webapp-sa-55466bf44",
            "uid": "b89dae55-e5f4-41e6-aa2b-e8e050bb28fb",
            "controller": true,
            "blockOwnerDeletion": true
          }
        ],
        "managedFields": [
          {
            "manager": "kube-controller-manager",
            "operation": "Update",
            "apiVersion": "v1",
            "time": "2021-06-09T22:26:40Z",
            "fieldsType": "FieldsV1",
            "fieldsV1": {"f:metadata":{"f:generateName":{},"f:labels":{".":{},"f:app":{},"f:pod-template-hash":{}},"f:ownerReferences":{".":{},"k:{\"uid\":\"b89dae55-e5f4-41e6-aa2b-e8e050bb28fb\"}":{".":{},"f:apiVersion":{},"f:blockOwnerDeletion":{},"f:controller":{},"f:kind":{},"f:name":{},"f:uid":{}}}},"f:spec":{"f:containers":{"k:{\"name\":\"alpine\"}":{".":{},"f:command":{},"f:image":{},"f:imagePullPolicy":{},"f:name":{},"f:resources":{},"f:terminationMessagePath":{},"f:terminationMessagePolicy":{}}},"f:dnsPolicy":{},"f:enableServiceLinks":{},"f:restartPolicy":{},"f:schedulerName":{},"f:securityContext":{},"f:serviceAccount":{},"f:serviceAccountName":{},"f:terminationGracePeriodSeconds":{}}}
          },
          {
            "manager": "calico",
            "operation": "Update",
            "apiVersion": "v1",
            "time": "2021-06-09T22:26:42Z",
            "fieldsType": "FieldsV1",
            "fieldsV1": {"f:metadata":{"f:annotations":{".":{},"f:cni.projectcalico.org/podIP":{},"f:cni.projectcalico.org/podIPs":{}}}}
          },
          {
            "manager": "kubelet",
            "operation": "Update",
            "apiVersion": "v1",
            "time": "2021-06-09T22:26:45Z",
            "fieldsType": "FieldsV1",
            "fieldsV1": {"f:status":{"f:conditions":{"k:{\"type\":\"ContainersReady\"}":{".":{},"f:lastProbeTime":{},"f:lastTransitionTime":{},"f:status":{},"f:type":{}},"k:{\"type\":\"Initialized\"}":{".":{},"f:lastProbeTime":{},"f:lastTransitionTime":{},"f:status":{},"f:type":{}},"k:{\"type\":\"Ready\"}":{".":{},"f:lastProbeTime":{},"f:lastTransitionTime":{},"f:status":{},"f:type":{}}},"f:containerStatuses":{},"f:hostIP":{},"f:phase":{},"f:podIP":{},"f:podIPs":{".":{},"k:{\"ip\":\"192.169.62.21\"}":{".":{},"f:ip":{}}},"f:startTime":{}}}
          }
        ]
      },
      "spec": {
        "volumes": [
          {
            "name": "kube-api-access-g2qll",
            "projected": {
              "sources": [
                {
                  "serviceAccountToken": {
                    "expirationSeconds": 3607,
                    "path": "token"
                  }
                },
                {
                  "configMap": {
                    "name": "kube-root-ca.crt",
                    "items": [
                      {
                        "key": "ca.crt",
                        "path": "ca.crt"
                      }
                    ]
                  }
                },
                {
                  "downwardAPI": {
                    "items": [
                      {
                        "path": "namespace",
                        "fieldRef": {
                          "apiVersion": "v1",
                          "fieldPath": "metadata.namespace"
                        }
                      }
                    ]
                  }
                }
              ],
              "defaultMode": 420
            }
          }
        ],
        "containers": [
          {
            "name": "alpine",
            "image": "alpine:latest",
            "command": [
              "sleep",
              "10000"
            ],
            "resources": {
              
            },
            "volumeMounts": [
              {
                "name": "kube-api-access-g2qll",
                "readOnly": true,
                "mountPath": "/var/run/secrets/kubernetes.io/serviceaccount"
              }
            ],
            "terminationMessagePath": "/dev/termination-log",
            "terminationMessagePolicy": "File",
            "imagePullPolicy": "Always"
          }
        ],
        "restartPolicy": "Always",
        "terminationGracePeriodSeconds": 30,
        "dnsPolicy": "ClusterFirst",
        "serviceAccountName": "webapp-sa",
        "serviceAccount": "webapp-sa",
        "nodeName": "kubenode1.jadbp.lab",
        "securityContext": {
          
        },
        "schedulerName": "default-scheduler",
        "tolerations": [
          {
            "key": "node.kubernetes.io/not-ready",
            "operator": "Exists",
            "effect": "NoExecute",
            "tolerationSeconds": 300
          },
          {
            "key": "node.kubernetes.io/unreachable",
            "operator": "Exists",
            "effect": "NoExecute",
            "tolerationSeconds": 300
          }
        ],
        "priority": 0,
        "enableServiceLinks": true,
        "preemptionPolicy": "PreemptLowerPriority"
      },
      "status": {
        "phase": "Running",
        "conditions": [
          {
            "type": "Initialized",
            "status": "True",
            "lastProbeTime": null,
            "lastTransitionTime": "2021-06-09T22:26:40Z"
          },
          {
            "type": "Ready",
            "status": "True",
            "lastProbeTime": null,
            "lastTransitionTime": "2021-06-09T22:26:44Z"
          },
          {
            "type": "ContainersReady",
            "status": "True",
            "lastProbeTime": null,
            "lastTransitionTime": "2021-06-09T22:26:44Z"
          },
          {
            "type": "PodScheduled",
            "status": "True",
            "lastProbeTime": null,
            "lastTransitionTime": "2021-06-09T22:26:40Z"
          }
        ],
        "hostIP": "192.168.1.161",
        "podIP": "192.169.62.21",
        "podIPs": [
          {
            "ip": "192.169.62.21"
          }
        ],
        "startTime": "2021-06-09T22:26:40Z",
        "containerStatuses": [
          {
            "name": "alpine",
            "state": {
              "running": {
                "startedAt": "2021-06-09T22:26:44Z"
              }
            },
            "lastState": {
              
            },
            "ready": true,
            "restartCount": 0,
            "image": "alpine:latest",
            "imageID": "docker-pullable://alpine@sha256:69e70a79f2d41ab5d637de98c1e0b055206ba40a8145e7bddb55ccc04e13cf8f",
            "containerID": "docker://378f033fa7c3d7f4af354b117d66c4b99b38245ce56ebc6ba84390a13d138f5a",
            "started": true
          }
        ],
        "qosClass": "BestEffort"
      }
    }
  ]
}/ # 
```