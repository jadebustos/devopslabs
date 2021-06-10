 # Añadiendo nuevos nodos al cluster

Si necesitaramos añadir un tercer nodo al cluster, worker3 con ip 192.168.1.163, lo primero que tenemos que hacer es seguir los mismos pasos que en el resto de workers y que se encuentran detallados en [00-00-instalando-kubernetes.md](00-00-instalando-kubernetes.md).

Al llegar al paso en el que hay que unir el nodo al clúster ejecutando **kubeadm join** deberemos generar un token.

Antes de eso en el master vamos a permitir las comunicaciones desde el nuevo nodo al master. Por lo tanto en el master deberemos ejecutar:

```console
[root@master ~]# firewall-cmd --permanent --add-rich-rule 'rule family=ipv4 source address=192.168.1.163/32 accept'
success
[root@master ~]# firewall-cmd --reload
success
[root@master ~]#
```

Podemos ver si tenemos algún token activo:

```console
[kubeadmin@master ~]$ kubeadm token list
[kubeadmin@master ~]$
```

Creamos un token e imprimimos el comando que es necesario ejecutar para que el nodo se una al clúster:

```console
[kubeadmin@master ~]$ kubeadm token create --print-join-command
kubeadm join 192.168.1.160:6443 --token 6kbm9j.0x7096yia5urrztm --discovery-token-ca-cert-hash sha256:b975164eb25204da0e13256af91390ad02e3287df399a1a9586cabd55f84ed9a 
[kubeadmin@master ~]$
```

Ejecutamos el comando anterior en el nodo:

 ```console
 [root@worker03 ~]# kubeadm join 192.168.1.160:6443 --token 6kbm9j.0x7096yia5urrztm --discovery-token-ca-cert-hash sha256:b975164eb25204da0e13256af91390ad02e3287df399a1a9586cabd55f84ed9a
[preflight] Running pre-flight checks
	[WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/
	[WARNING FileExisting-tc]: tc not found in system path
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

[root@worker03 ~]#
 ```

 El nodo se unirá al clúster:

 ```console
 [kubeadmin@master ~]$ kubectl get nodes
NAME                   STATUS   ROLES                  AGE    VERSION
master.jadbp.lab   Ready    control-plane,master   42h    v1.21.1
worker01.jadbp.lab    Ready    <none>                 42h    v1.21.1
worker02.jadbp.lab    Ready    <none>                 154m   v1.21.1
worker03.jadbp.lab    Ready    <none>                 24m    v1.21.1
[kubeadmin@master ~]$ 
 ```