# Utilizando providers no oficiales

Terraform incluye una gran cantidad de providers pero puede haber infraestructura de la que Terraform no tenga provider oficial. Como por ejemplo para desplegar sobre **KVM** o **VirtualBox**.

En el directorio [labs](../../labs) se encuentra un ejemplo de como instalar un provider no oficial, el de **KVM**, y como desplegar un par de máquinas virtuales. En concreto las máquinas virtuales para los laboratorios de docker y podman.

En el directorio [kvm](../../kvm) se encuentran los planes de Terraform para desplegar dichas máquinas virtuales.