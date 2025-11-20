# cloud-init

## Configuración del hipervisor

En el hipervisor es necesario instalar **cloud-utils**. Para sistemas basados en RPM:

```bash
# yum install cloud-utils -y
```

## Configuración de la máquina virtual

Para configurar la máquina virtual vía cloud-init es necesario instalar **cloud-init**. Para sistemas basados en RPM:

```bash
# yum install cloud-init -y
```

Será necesario activar los servicios de cloud-init:

```bash
# systemctl enable cloud-init-local.service
# systemctl enable cloud-init.service
# systemctl enable cloud-config.service
# systemctl enable cloud-final.service
```

> ![IMPORTANT](../imgs/important-icon.png): No instalar **cloud-init** en el hipervisor.

## Recursos

+ [Documentación de cloud-init](https://cloudinit.readthedocs.io/en/latest/)
+ [Ejemplos de configuración](https://cloudinit.readthedocs.io/en/latest/topics/examples.html)
+ [Cloud-init FAQ](https://cloudinit.readthedocs.io/en/latest/topics/faq.html)