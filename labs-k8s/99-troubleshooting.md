# Troubleshooting

## Primer despliegue

Realizamos un deployment que se tenga que descargar una imagen:

```console
[kubeadmin@kubemaster first-app]$ kubectl apply -f first-app.yaml
...
[kubeadmin@kubemaster first-app]$
```

Depués de crear el deployment podemos ver el estado del POD:

```console
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=default
NAME                      READY   STATUS              RESTARTS   AGE
webapp-68965f4fcc-bz87h   0/1     ContainerCreating   0          2m31s
[kubeadmin@kubemaster first-app]$ kubectl describe pod webapp-68965f4fcc-bz87h
Name:           webapp-68965f4fcc-bz87h
Namespace:      default
Priority:       0
Node:           kubenode1.acme.es/192.168.1.111
Start Time:     Sun, 24 Jan 2021 17:50:14 +0100
Labels:         app=webapp
                pod-template-hash=68965f4fcc
Annotations:    cni.projectcalico.org/podIP: 10.214.112.1/32
                cni.projectcalico.org/podIPs: 10.214.112.1/32
Status:         Pending
IP:             
IPs:            <none>
Controlled By:  ReplicaSet/webapp-68965f4fcc
Containers:
  webapp:
    Container ID:   
    Image:          quay.io/rhte_2019/php:7-apache
    Image ID:       
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Waiting
      Reason:       ContainerCreating
    Ready:          False
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-flf64 (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             False 
  ContainersReady   False 
  PodScheduled      True 
Volumes:
  default-token-flf64:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-flf64
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                 node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  2m51s  default-scheduler  Successfully assigned default/webapp-68965f4fcc-bz87h to kubenode1.acme.es
  Normal  Pulling    2m49s  kubelet            Pulling image "quay.io/rhte_2019/php:7-apache"
[kubeadmin@kubemaster first-app]$ 
```

Vemos que está descargandose la imagen. Podemos ver los eventos del namespace para ver que está pasando:

```console
[kubeadmin@kubemaster first-app]$ kubectl get events --namespace=default
LAST SEEN   TYPE      REASON                    OBJECT                         MESSAGE
14m         Normal    Starting                  node/kubemaster.acme.es            Starting kubelet.
14m         Normal    NodeHasSufficientMemory   node/kubemaster.acme.es            Node kubemaster.acme.es status is now: NodeHasSufficientMemory
14m         Normal    NodeHasNoDiskPressure     node/kubemaster.acme.es            Node kubemaster.acme.es status is now: NodeHasNoDiskPressure
14m         Normal    NodeHasSufficientPID      node/kubemaster.acme.es            Node kubemaster.acme.es status is now: NodeHasSufficientPID
14m         Normal    NodeAllocatableEnforced   node/kubemaster.acme.es            Updated Node Allocatable limit across pods
13m         Normal    Starting                  node/kubemaster.acme.es            Starting kube-proxy.
13m         Normal    RegisteredNode            node/kubemaster.acme.es            Node kubemaster.acme.es event: Registered Node kubemaster.acme.es in Controller
4m42s       Normal    Scheduled                 pod/webapp-68965f4fcc-bz87h    Successfully assigned default/webapp-68965f4fcc-bz87h to kubenode1.acme.es
4m40s       Normal    Pulling                   pod/webapp-68965f4fcc-bz87h    Pulling image "quay.io/rhte_2019/php:7-apache"
4m42s       Normal    SuccessfulCreate          replicaset/webapp-68965f4fcc   Created pod: webapp-68965f4fcc-bz87h
4m42s       Normal    ScalingReplicaSet         deployment/webapp              Scaled up replica set webapp-68965f4fcc to 1
63m         Normal    Starting                  node/kubenode1.acme.es          Starting kubelet.
63m         Normal    NodeHasSufficientMemory   node/kubenode1.acme.es          Node kubenode1.acme.es status is now: NodeHasSufficientMemory
63m         Normal    NodeHasNoDiskPressure     node/kubenode1.acme.es          Node kubenode1.acme.es status is now: NodeHasNoDiskPressure
63m         Normal    NodeHasSufficientPID      node/kubenode1.acme.es          Node kubenode1.acme.es status is now: NodeHasSufficientPID
63m         Normal    NodeAllocatableEnforced   node/kubenode1.acme.es          Updated Node Allocatable limit across pods
63m         Normal    RegisteredNode            node/kubenode1.acme.es          Node kubenode1.acme.es event: Registered Node kubenode1.acme.es in Controller
58m         Normal    Starting                  node/kubenode1.acme.es          Starting kube-proxy.
55m         Normal    NodeReady                 node/kubenode1.acme.es          Node kubenode1.acme.es status is now: NodeReady
13m         Normal    Starting                  node/kubenode1.acme.es          Starting kubelet.
13m         Normal    NodeHasSufficientMemory   node/kubenode1.acme.es          Node kubenode1.acme.es status is now: NodeHasSufficientMemory
13m         Normal    NodeHasNoDiskPressure     node/kubenode1.acme.es          Node kubenode1.acme.es status is now: NodeHasNoDiskPressure
13m         Normal    NodeHasSufficientPID      node/kubenode1.acme.es          Node kubenode1.acme.es status is now: NodeHasSufficientPID
13m         Normal    NodeAllocatableEnforced   node/kubenode1.acme.es          Updated Node Allocatable limit across pods
13m         Warning   Rebooted                  node/kubenode1.acme.es          Node kubenode1.acme.es has been rebooted, boot id: 7967d707-daa6-42d1-806a-50af11595a34
13m         Normal    Starting                  node/kubenode1.acme.es          Starting kube-proxy.
13m         Normal    RegisteredNode            node/kubenode1.acme.es          Node kubenode1.acme.es event: Registered Node kubenode1.acme.es in Controller
61m         Normal    Starting                  node/kubenode2.acme.es          Starting kubelet.
61m         Normal    NodeHasSufficientMemory   node/kubenode2.acme.es          Node kubenode2.acme.es status is now: NodeHasSufficientMemory
61m         Normal    NodeHasNoDiskPressure     node/kubenode2.acme.es          Node kubenode2.acme.es status is now: NodeHasNoDiskPressure
61m         Normal    NodeHasSufficientPID      node/kubenode2.acme.es          Node kubenode2.acme.es status is now: NodeHasSufficientPID
61m         Normal    NodeAllocatableEnforced   node/kubenode2.acme.es          Updated Node Allocatable limit across pods
61m         Normal    RegisteredNode            node/kubenode2.acme.es          Node kubenode2.acme.es event: Registered Node kubenode2.acme.es in Controller
55m         Normal    Starting                  node/kubenode2.acme.es          Starting kube-proxy.
50m         Normal    NodeReady                 node/kubenode2.acme.es          Node kubenode2.acme.es status is now: NodeReady
13m         Normal    RegisteredNode            node/kubenode2.acme.es          Node kubenode2.acme.es event: Registered Node kubenode2.acme.es in Controller
13m         Normal    Starting                  node/kubenode2.acme.es          Starting kubelet.
13m         Normal    NodeHasSufficientMemory   node/kubenode2.acme.es          Node kubenode2.acme.es status is now: NodeHasSufficientMemory
13m         Normal    NodeHasNoDiskPressure     node/kubenode2.acme.es          Node kubenode2.acme.es status is now: NodeHasNoDiskPressure
13m         Normal    NodeHasSufficientPID      node/kubenode2.acme.es          Node kubenode2.acme.es status is now: NodeHasSufficientPID
13m         Normal    NodeAllocatableEnforced   node/kubenode2.acme.es          Updated Node Allocatable limit across pods
13m         Warning   Rebooted                  node/kubenode2.acme.es          Node kubenode2.acme.es has been rebooted, boot id: 856cf36f-be3d-4d90-b54a-553d8be4dc69
13m         Normal    Starting                  node/kubenode2.acme.es          Starting kube-proxy.
[kubeadmin@kubemaster first-app]$ 
```

Podemos consultar el yaml para ver exactamente la configuración del deployment:

```console
[kubeadmin@kubemaster first-app]$ kubectl get pod webapp-68965f4fcc-bz87h -o yaml >  webapp-68965f4fcc-bz87h.yaml
```

También podemos ejecutar una shell en el contenedor:

```console
[kubeadmin@kubemaster first-app]$ kubectl get pods --namespace=default
NAME                      READY   STATUS    RESTARTS   AGE
webapp-68965f4fcc-bz87h   1/1     Running   0          43m
[kubeadmin@kubemaster first-app]$ kubectl exec --stdin --tty webapp-68965f4fcc-bz87h -- /bin/bash
root@webapp-68965f4fcc-bz87h:/var/www/html# root@webapp-68965f4fcc-bz87h:/var/www/html# whoami
root
root@webapp-68965f4fcc-bz87h:/var/www/html# 
```