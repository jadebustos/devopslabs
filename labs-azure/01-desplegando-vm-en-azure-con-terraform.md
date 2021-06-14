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

## Despliegue

Para desplegar

 ```console
[user@terraform single-vm]$ terraform init
Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/azurerm from the dependency lock file
- Using previously-installed hashicorp/azurerm v2.46.1

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
[user@terraform single-vm]$ 
...
```

Podemos revisar el plan:

```console
[user@terraform single-vm]$ terraform plan
...
  # azurerm_virtual_network.myNet will be created
  + resource "azurerm_virtual_network" "myNet" {
      + address_space         = [
          + "10.0.0.0/16",
        ]
      + guid                  = (known after apply)
      + id                    = (known after apply)
      + location              = "westeurope"
      + name                  = "kubernetesnet"
      + resource_group_name   = "kubernetes_rg"
      + subnet                = (known after apply)
      + tags                  = {
          + "environment" = "CP2"
        }
      + vm_protection_enabled = false
    }

Plan: 9 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
[user@terraform single-vm]$
```

Podemos revisar el plan y si está correcto podemos aplicarlo. Dado que terraform define el estado deseado, pero no como llegar a el, si ejecutamos el plan no tenemos garantías de que los pasos se ejecuten en el orden que hemos visto. En este caso no hay dependencias ([depends_on](https://www.terraform.io/docs/language/meta-arguments/depends_on.html)) con lo cual el orden no nos importa ya que no habrá error por falta de algún recurso que no haya sido creado.

Si quisieramos que se ejecutara en el orden que hemos revisado será necesario generar y guardar el plan:

```console
[user@terraform single-vm]$ terraform plan -out myplan.txt
...
  # azurerm_subnet.mySubnet will be created
  + resource "azurerm_subnet" "mySubnet" {
      + address_prefix                                 = (known after apply)
      + address_prefixes                               = [
          + "10.0.1.0/24",
        ]
      + enforce_private_link_endpoint_network_policies = false
      + enforce_private_link_service_network_policies  = false
      + id                                             = (known after apply)
      + name                                           = "terraformsubnet"
      + resource_group_name                            = "kubernetes_rg"
      + virtual_network_name                           = "kubernetesnet"
    }

  # azurerm_virtual_network.myNet will be created
  + resource "azurerm_virtual_network" "myNet" {
      + address_space         = [
          + "10.0.0.0/16",
        ]
      + guid                  = (known after apply)
      + id                    = (known after apply)
      + location              = "westeurope"
      + name                  = "kubernetesnet"
      + resource_group_name   = "kubernetes_rg"
      + subnet                = (known after apply)
      + tags                  = {
          + "environment" = "CP2"
        }
      + vm_protection_enabled = false
    }

Plan: 9 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Saved the plan to: myplan.txt

To perform exactly these actions, run the following command to apply:
    terraform apply "myplan.txt"
[user@terraform single-vm]$
```

Para empezar el despliegue, sin importarnos el orden:

```console
[user@terraform single-vm]$ terraform apply
...
  # azurerm_virtual_network.myNet will be created
  + resource "azurerm_virtual_network" "myNet" {
      + address_space         = [
          + "10.0.0.0/16",
        ]
      + guid                  = (known after apply)
      + id                    = (known after apply)
      + location              = "westeurope"
      + name                  = "kubernetesnet"
      + resource_group_name   = "kubernetes_rg"
      + subnet                = (known after apply)
      + tags                  = {
          + "environment" = "CP2"
        }
      + vm_protection_enabled = false
    }

Plan: 9 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
  ...
[user@terraform single-vm]$
```

Nos pedirá confirmación, podemos revisar el plan y el orden en el que se realizará. Solo se iniciará el despliegue si confirmamos con **yes**.

Sin embargo, si ejecutamos el apply con la salida generada anteriormente el plan se ejecutará inmediatamente sin pedir confirmación:

```console
[user@terraform single-vm]$ terraform apply myplan.txt
azurerm_resource_group.rg: Creating...
azurerm_resource_group.rg: Creation complete after 0s [id=/subscriptions/7a4e1967-660f-4ee9-bafb-fd3522c7ef52/resourceGroups/kubernetes_rg]
azurerm_public_ip.myPublicIp1: Creating...
azurerm_virtual_network.myNet: Creating...
azurerm_network_security_group.mySecGroup: Creating...
azurerm_storage_account.stAccount: Creating...
azurerm_public_ip.myPublicIp1: Creation complete after 3s [id=/subscriptions/7a4e1967-660f-4ee9-bafb-fd3522c7ef52/resourceGroups/kubernetes_rg/providers/Microsoft.Network/publicIPAddresses/vmip1]
azurerm_network_security_group.mySecGroup: Creation complete after 5s [id=/subscriptions/7a4e1967-660f-4ee9-bafb-fd3522c7ef52/resourceGroups/kubernetes_rg/providers/Microsoft.Network/networkSecurityGroups/sshtraffic]
azurerm_virtual_network.myNet: Creation complete after 5s [id=/subscriptions/7a4e1967-660f-4ee9-bafb-fd3522c7ef52/resourceGroups/kubernetes_rg/providers/Microsoft.Network/virtualNetworks/kubernetesnet]
azurerm_subnet.mySubnet: Creating...
azurerm_subnet.mySubnet: Creation complete after 4s [id=/subscriptions/7a4e1967-660f-4ee9-bafb-fd3522c7ef52/resourceGroups/kubernetes_rg/providers/Microsoft.Network/virtualNetworks/kubernetesnet/subnets/terraformsubnet]
azurerm_network_interface.myNic1: Creating...
azurerm_storage_account.stAccount: Still creating... [10s elapsed]
azurerm_network_interface.myNic1: Creation complete after 2s [id=/subscriptions/7a4e1967-660f-4ee9-bafb-fd3522c7ef52/resourceGroups/kubernetes_rg/providers/Microsoft.Network/networkInterfaces/vmnic1]
azurerm_network_interface_security_group_association.mySecGroupAssociation1: Creating...
azurerm_network_interface_security_group_association.mySecGroupAssociation1: Creation complete after 1s [id=/subscriptions/7a4e1967-660f-4ee9-bafb-fd3522c7ef52/resourceGroups/kubernetes_rg/providers/Microsoft.Network/networkInterfaces/vmnic1|/subscriptions/7a4e1967-660f-4ee9-bafb-fd3522c7ef52/resourceGroups/kubernetes_rg/providers/Microsoft.Network/networkSecurityGroups/sshtraffic]
azurerm_storage_account.stAccount: Still creating... [20s elapsed]
azurerm_storage_account.stAccount: Creation complete after 26s [id=/subscriptions/7a4e1967-660f-4ee9-bafb-fd3522c7ef52/resourceGroups/kubernetes_rg/providers/Microsoft.Storage/storageAccounts/stgeaccountunircp2]
azurerm_linux_virtual_machine.myVM1: Creating...
azurerm_linux_virtual_machine.myVM1: Still creating... [10s elapsed]
azurerm_linux_virtual_machine.myVM1: Still creating... [20s elapsed]
azurerm_linux_virtual_machine.myVM1: Still creating... [30s elapsed]
azurerm_linux_virtual_machine.myVM1: Still creating... [40s elapsed]
azurerm_linux_virtual_machine.myVM1: Still creating... [50s elapsed]
azurerm_linux_virtual_machine.myVM1: Still creating... [1m0s elapsed]
azurerm_linux_virtual_machine.myVM1: Still creating... [1m10s elapsed]
azurerm_linux_virtual_machine.myVM1: Still creating... [1m20s elapsed]
azurerm_linux_virtual_machine.myVM1: Still creating... [1m30s elapsed]
azurerm_linux_virtual_machine.myVM1: Still creating... [1m40s elapsed]
azurerm_linux_virtual_machine.myVM1: Still creating... [1m50s elapsed]
azurerm_linux_virtual_machine.myVM1: Creation complete after 1m55s [id=/subscriptions/7a4e1967-660f-4ee9-bafb-fd3522c7ef52/resourceGroups/kubernetes_rg/providers/Microsoft.Compute/virtualMachines/my-first-azure-vm]

Apply complete! Resources: 9 added, 0 changed, 0 destroyed.
[user@terraform single-vm]$
```

Podemos ver el estado ejecutando **terraform show**.

> ![TIP](../imgs/tip-icon.png) El revisar el orden en el que se ejecutará el plan y asegurar que dicho orden se cumple es algo que irá cobrando importancia a medida que añadimos infraestructura ya que llegará el caso en el que haya dependencias de recursos que deberán estar creados para crear otros a medida que la infraestructura crece.