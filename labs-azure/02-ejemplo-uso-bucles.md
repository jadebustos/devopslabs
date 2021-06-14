# Ejemplo del uso de bucles

Vamos a ilustrar el uso de bucles.

Para ello utilizaremos el ejemplo anterior. Suponiendo que lo hemos desplegado, vamos a crear utilizando bucles una serie de redes nuevas para, por ejemplo, crear entornos de **dev** y **pre**.

En fichero [vars.tf](single-vm/vars.tf) añadimos lo siguiente:

```yaml
variable "entornos" {
  type = list(string)
  description = "Entornos"
  default = ["dev", "pre"]
}
```

Crearemos dos entornos **dev** y **pre** e iteraremos sobre dicha lista para crear las redes adicionales.

Vamos a crear subredes dentro del espacio de direccionamiento definido en la red definida en [network.tf](single-vm/network.tf). Para ello creamos el fichero **network-entornos.tf**:

```yaml
# Creación de subnets adicionales
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet

resource "azurerm_subnet" "mySubnetEnv" {
    count                  = length(var.entornos)
    name                   = "terraformsubnet-${var.entornos[count.index]}"
    resource_group_name    = azurerm_resource_group.rg.name
    virtual_network_name   = azurerm_virtual_network.myNet.name
    address_prefixes       = ["10.0.${count.index + 30}.0/24"]
}
```

 + **count** indica el número de iteraciones que se realizarán. Como hay dos elementos en la lista **entornos** se realizarán dos iteraciones.
 + **name** se crearán dos subredes y deberán tener nombres diferentes. Como se harán dos iteraciones, **count** tomará los valores **0** y **1**. Estos valores se almacenarán en **count.index** en cada iteración por lo tanto los nombres que se asignarán serán **terraformsubnet-dev** y **terraformsubnet-pre**.
 + **address_prefixes** indicará el direccionamiento de cada subred, que deberá ser diferente y los direccionamientos asignados serán **10.0.30.0/24** y **10.0.31.0/24**.

 Una vez creados los ficheros en el directorio donde se encuentra el plan para crear las nuevas redes ejecutaremos:

```console
[user@terraform single-vm]$ terraform apply
...
```
