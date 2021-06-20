# Egress

El tráfico egress es el tráfico saliente. Por defecto está todo el tráfico saliente permitido.

## Despliegue de pods

Vamos a desplegar un pod con utilidades de red para realizar una serie de pruebas:

```console
[kubeadmin@kubemaster egress]$ kubectl apply -f egress.yaml 
namespace/egress-example created
deployment.apps/egress-example created
[kubeadmin@kubemaster egress]$ 
```

```console
[kubeadmin@kubemaster egress]$ kubectl exec -i -t egress-example-58d46875f7-fpsln --namespace egress-example -- nslookup www.google.com
Server:		10.96.0.10
Address:	10.96.0.10#53

Non-authoritative answer:
Name:	www.google.com
Address: 142.250.184.4

[kubeadmin@kubemaster egress]$ kubectl -n kube-system get svc -l k8s-app=kube-dns
NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   12d
[kubeadmin@kubemaster egress]$ 
```

```console
[kubeadmin@kubemaster egress]$ kubectl exec -i -t egress-example-58d46875f7-fpsln --namespace egress-example -- ping -c 4 8.8.8.8
PING 8.8.8.8 (8.8.8.8): 56 data bytes
64 bytes from 8.8.8.8: icmp_seq=0 ttl=114 time=12.309 ms
64 bytes from 8.8.8.8: icmp_seq=1 ttl=114 time=10.330 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=114 time=11.438 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=114 time=10.901 ms
--- 8.8.8.8 ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max/stddev = 10.330/11.244/12.309/0.729 ms
[kubeadmin@kubemaster egress]$
```