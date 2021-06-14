# Utilizando providers no oficiales

Terraform incluye una gran cantidad de providers pero puede haber infraestructura de la que Terraform no tenga provider oficial. Como por ejemplo para desplegar sobre **KVM** o **VirtualBox**.

En el directorio [labs](../labs/README.md) se encuentra un ejemplo de como instalar un provider no oficial, el de **KVM**, y como desplegar un par de máquinas virtuales. En concreto las máquinas virtuales para los laboratorios de docker y podman.

En el directorio [terraform](../terraform/README.md) se encuentran los planes de Terraform para desplegar dichas máquinas virtuales.