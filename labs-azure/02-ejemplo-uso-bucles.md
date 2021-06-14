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

Vamos a crear subredes dentro del espacio de direccionamiento definido en la red definida en [network.tf](single-vm/network.tf). Para ello creamos el fichero **network-env.tf**:

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
Terraform will perform the following actions:

  # azurerm_subnet.mySubnetEnv[0] will be created
  + resource "azurerm_subnet" "mySubnetEnv" {
      + address_prefix                                 = (known after apply)
      + address_prefixes                               = [
          + "10.0.30.0/24",
        ]
      + enforce_private_link_endpoint_network_policies = false
      + enforce_private_link_service_network_policies  = false
      + id                                             = (known after apply)
      + name                                           = "terraformsubnet-dev"
      + resource_group_name                            = "kubernetes_rg"
      + virtual_network_name                           = "kubernetesnet"
    }

  # azurerm_subnet.mySubnetEnv[1] will be created
  + resource "azurerm_subnet" "mySubnetEnv" {
      + address_prefix                                 = (known after apply)
      + address_prefixes                               = [
          + "10.0.31.0/24",
        ]
      + enforce_private_link_endpoint_network_policies = false
      + enforce_private_link_service_network_policies  = false
      + id                                             = (known after apply)
      + name                                           = "terraformsubnet-pre"
      + resource_group_name                            = "kubernetes_rg"
      + virtual_network_name                           = "kubernetesnet"
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

azurerm_subnet.mySubnetEnv[1]: Creating...
azurerm_subnet.mySubnetEnv[0]: Creating...
azurerm_subnet.mySubnetEnv[0]: Creation complete after 4s [id=/subscriptions/7a4e1967-660f-4ee9-bafb-fd3522c7ef52/resourceGroups/kubernetes_rg/providers/Microsoft.Network/virtualNetworks/kubernetesnet/subnets/terraformsubnet-dev]
azurerm_subnet.mySubnetEnv[1]: Creation complete after 7s [id=/subscriptions/7a4e1967-660f-4ee9-bafb-fd3522c7ef52/resourceGroups/kubernetes_rg/providers/Microsoft.Network/virtualNetworks/kubernetesnet/subnets/terraformsubnet-pre]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
[user@terraform single-vm]$
```

## Añadiendo más redes

Supongamos que nos surge el requerimiento de crear otro entorno adicional,**QA**. Entonces modificaremos el fichero [vars.tf](single-vm/vars.tf) de tal forma que:

```yaml
variable "entornos" {
  type = list(string)
  description = "Entornos"
  default = ["dev", "pre", "qa"]
}
```

Y a continuación hacemos el apply:

```console
[user@terraform single-vm]$ terraform apply
...
Terraform will perform the following actions:

  # azurerm_subnet.mySubnetEnv[2] will be created
  + resource "azurerm_subnet" "mySubnetEnv" {
      + address_prefix                                 = (known after apply)
      + address_prefixes                               = [
          + "10.0.32.0/24",
        ]
      + enforce_private_link_endpoint_network_policies = false
      + enforce_private_link_service_network_policies  = false
      + id                                             = (known after apply)
      + name                                           = "terraformsubnet-qa"
      + resource_group_name                            = "kubernetes_rg"
      + virtual_network_name                           = "kubernetesnet"
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

azurerm_subnet.mySubnetEnv[2]: Creating...
azurerm_subnet.mySubnetEnv[2]: Creation complete after 4s [id=/subscriptions/7a4e1967-660f-4ee9-bafb-fd3522c7ef52/resourceGroups/kubernetes_rg/providers/Microsoft.Network/virtualNetworks/kubernetesnet/subnets/terraformsubnet-qa]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
[user@terraform single-vm]$
```

Terraform comprobará el estado real y creará lo que falta, en este caso la red **qa** que hemos definido.

Observar que ahora existen tres elementos en la variable **entornos** y **count.index** tomará los valores **0**, **1** y **2**.