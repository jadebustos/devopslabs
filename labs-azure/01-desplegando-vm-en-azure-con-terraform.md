# Desplegando una máquina virtual en Azure con Terraform

Distrubiremos el plan de Terraform en varios ficheros.

## main.tf

En el fichero [main.tf](single-vm/main.tf) incluiremos el código Terraform con los datos del provider y crearemos:

+ El [grupo de recursos](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) donde crearemos toda la infraestructura necesaria.
+ Una [Storage account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) para almacenar información sobre el despliegue.

## vars.tf

En el fichero [vars.tf](single-vm/vars.tf) incluiremos las variables que vayamos a utilizar.

## network.tf

En el fichero [network.tf](single-vm/network.tf) incluiremos los recursos de red que vayamos a utilizar.

Necesitaremos crear:

+ Una red, **10.0.0.0/16**.
+ Una subred dentro de la red anterior que será donde se conectarán las máquinas virtuales, **10.0.1.0/24**.
+ Una tarjeta de red que deberemos asignar a la subred anterior.
+ Una dirección IP pública para poder acceder a ella desde fuera de Azure.

## security.tf

En el fichero [security.tf](single-vm/security.tf) incluiremos los recursos de seguridad que vayamos a utilizar.

## vm.tf

En el fichero [vm.tf](single-vm/vm.tf) incluiremos la definición de la vm red que vayamos a crear.