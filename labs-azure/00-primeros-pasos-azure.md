# Primeros pasos con Azure

## Instalación del CLI de Azure

Aunque vamos a desplegar la infraestructura con Terraform algunas operaciones las haremos con el CLI de Azure. Por ejemplo buscar imágenes para desplegar las VMs.

Deberemos instalar el CLI de Azure en la misma máquina en la que se encuentre instalado o vayamos a instalar Terraform. De esta forma haremos todo desde la misma máquina. No es necesario que este todo en la misma máquina, pero por comodidad se recomienda.

[Install the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

## Crear un Service Principal para autenticarnos en Azure

Para poder autenticarnos con el CLI de Azure necesitaremos crear un [Service Principal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)

Si lo hacemos desde la consola ejecutaremos el comando:

```console
$ az login
The default web browser has been opened at https://login.microsoftonline.com/common/oauth2/authorize. Please continue the login in the web browser. If no web browser is available or if the web browser fails to open, use device code flow with `az login --use-device-code`.
You have logged in. Now let us find all the subscriptions to which you have access...
[
  {
    "cloudName": "AzureCloud",
    "homeTenantId": "f8389572-8716-463a-b0ad-8e694a1e9119",
    "id": "728eb5ad-f695-4cfb-a220-25fdd575a4ff",
    "isDefault": true,
    "managedByTenants": [],
    "name": "Pay-As-You-Go",
    "state": "Enabled",
    "tenantId": "f8389572-8716-463a-b0ad-8e694a1e9119",
    "user": {
      "name": "youruser@here",
      "type": "user"
    }
  }
]
$ 
```

Si disponemos de varias subscripciones de Azure podemos indicar la subscripción sobre la que vamos a trabajar:

```console
$ az account set --subscription="SUBSCRIPTION_ID"
```

Esto nos abrirá un navegador para que nos autentiquemos. Una vez autenticados creamos el Service Principal:

```console
$ az ad sp create-for-rbac --role="Contributor"
Creating 'Contributor' role assignment under scope '/subscriptions/b12b6cba-621c-4f49-8a70-a7f2e2f233ea'
  Retrying role assignment creation: 1/36
The output includes credentials that you must protect. Be sure that you do not include these credentials in your code or check the credentials into your source control. For more information, see https://aka.ms/azadsp-cli
{
  "appId": "97c6977a-e7b8-42cc-9e2d-bec4eb73b99d",
  "displayName": "azure-cli-2017-09-18-08-13-59",
  "name": "http://azure-cli-2017-09-18-08-13-59",
  "password": "GU2KaJYR2-Wr2D2GQcm7Las8hkH4vG1A6c",
  "tenant": "f8389572-8716-463a-b0ad-8e694a1e9119"
}
$ 
```

> ![TIP](../imgs/tip-icon.png) Puedes asignarle un **displayName** para que sea más fácil localizar el Service Principal:
> ```console
> $ az ad sp create-for-rbac --help
> ```


```console
$ az ad sp list --display-name azure-cli-2017-09-18-08-13-59
...
$
```

Para indicar actuar sobre una determinada subscripción:

```console
$ az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/SUBSCRIPTION_ID"
```

En el provider de Terraform deberemos incluir estos datos:

```yaml
provider "azurerm" {
  features {}
  subscription_id = "97c6977a-e7b8-42cc-9e2d-bec4eb73b99d"
  client_id       = "c49e59f7-628a-4537-89cc-5e2e1a521267" # appID
  client_secret   = "GU2KaJYR2-Wr2D2GQcm7Las8hkH4vG1A6c"   # password
  tenant_id       = "f8389572-8716-463a-b0ad-8e694a1e9119" # tenant
}
```

En el portal de Azure podemos ir a **Azure Active Directory -> Enterprise Applications** y si buscamos por el **appID** podemos consultar/modificar la Service Account.

## Buscando una imagen para desplegar los servidores

Podemos crear nuestra propia imagen y subirla, pero vamos a utilizar imágenes ya disponibles en Azure. Para ello podemos ver que tipo de imagenes hay disponibles en el marketplace:

```console
$ az vm image list --output table
You are viewing an offline list of images, use --all to retrieve an up-to-date list
Offer          Publisher               Sku                 Urn                                                             UrnAlias             Version
-------------  ----------------------  ------------------  --------------------------------------------------------------  -------------------  ---------
CentOS         OpenLogic               7.5                 OpenLogic:CentOS:7.5:latest                                     CentOS               latest
CoreOS         CoreOS                  Stable              CoreOS:CoreOS:Stable:latest                                     CoreOS               latest
debian-10      Debian                  10                  Debian:debian-10:10:latest                                      Debian               latest
openSUSE-Leap  SUSE                    42.3                SUSE:openSUSE-Leap:42.3:latest                                  openSUSE-Leap        latest
RHEL           RedHat                  7-LVM               RedHat:RHEL:7-LVM:latest                                        RHEL                 latest
SLES           SUSE                    15                  SUSE:SLES:15:latest                                             SLES                 latest
UbuntuServer   Canonical               18.04-LTS           Canonical:UbuntuServer:18.04-LTS:latest                         UbuntuLTS            latest
WindowsServer  MicrosoftWindowsServer  2019-Datacenter     MicrosoftWindowsServer:WindowsServer:2019-Datacenter:latest     Win2019Datacenter    latest
WindowsServer  MicrosoftWindowsServer  2016-Datacenter     MicrosoftWindowsServer:WindowsServer:2016-Datacenter:latest     Win2016Datacenter    latest
WindowsServer  MicrosoftWindowsServer  2012-R2-Datacenter  MicrosoftWindowsServer:WindowsServer:2012-R2-Datacenter:latest  Win2012R2Datacenter  latest
WindowsServer  MicrosoftWindowsServer  2012-Datacenter     MicrosoftWindowsServer:WindowsServer:2012-Datacenter:latest     Win2012Datacenter    latest
WindowsServer  MicrosoftWindowsServer  2008-R2-SP1         MicrosoftWindowsServer:WindowsServer:2008-R2-SP1:latest         Win2008R2SP1         latest
[jadebustos@archimedes azure]$ 
```

Luego podemos buscar los tipos de imágenes que hay del tipo que nos interese:

```console
$ az vm image list --offer CentOS --all --output table > centos
```

El fichero **centos**:

```bash
Offer              Publisher  Sku          Urn                                        Version
------------------ ---------- ------------ ------------------------------------------ ---------
centos-solver195   ansys      74-rc2-hpc   ansys:centos-solver195:74-rc2-hpc:1.20.14  1.20.14
...
```

Para poder utilizar una imagen deberemos aceptar los términos de uso, de no hacerlo no podremos desplegar con ella y obtendremos un error:

```
Error: creating Linux Virtual Machine "my-first-azure-vm" (Resource Group "kubernetes_rg"): compute.VirtualMachinesClient#CreateOrUpdate: Failure sending request: StatusCode=400 -- Original Error: Code="ResourcePurchaseValidationFailed" Message="User failed validation to purchase resources. Error message: 'You have not accepted the legal terms on this subscription: '97c6977a-e7b8-42cc-9e2d-bec4eb73b99d' for this plan. Before the subscription can be used, you need to accept the legal terms of the image. To read and accept legal terms, use the Azure CLI commands described at https://go.microsoft.com/fwlink/?linkid=2110637 or the PowerShell commands available at https://go.microsoft.com/fwlink/?linkid=862451. Alternatively, deploying via the Azure portal provides a UI experience for reading and accepting the legal terms. Offer details: publisher='procomputers' offer = 'centos-8-latest', sku = 'centos-8-latest', Correlation Id: '53f72879-c992-4b15-aadb-f6297f223221'.'"
```

Utilizando el valor de la column **Urn** podemos obtener información de la imagen y consultar los términos de uso:

```console
$ az vm image terms show --urn cognosys:centos-8-stream-free:centos-8-stream-free:1.2019.0810
{
  "accepted": false,
  "id": "/subscriptions/b12b6cba-621c-4f49-8a70-a7f2e2f233ea/providers/Microsoft.MarketplaceOrdering/offerTypes/VirtualMachine/publishers/cognosys/offers/centos-8-stream-free/plans/centos-8-stream-free/agreements/current",
  "licenseTextLink": "https://storelegalterms.blob.core.windows.net/legalterms/3E5ED_legalterms_COGNOSYS%253a24CENTOS%253a2D8%253a2DSTREAM%253a2DFREE%253a24CENTOS%253a2D8%253a2DSTREAM%253a2DFREE%253a24CCYSNQWELVORSIA5MDTVHE6FPIZ5GCO3T6OUM53IUP4XFKJY2B4QTN6L43QJMNSF7SRMTP24UPT5LWRG35IQ7SJVHFMLGFEXMXKVQGI.txt",
  "name": "centos-8-stream-free",
  "plan": "centos-8-stream-free",
  "privacyPolicyLink": "http://www.cogno-sys.com/cognosys-technologies-partners/privacy-policy/",
  "product": "centos-8-stream-free",
  "publisher": "cognosys",
  "retrieveDatetime": "2021-02-07T11:00:43.4843829Z",
  "signature": "UOGSUJEVQWI3FZYQH6IDDOMBEPMKX3V6CEMS2VF3YQBJFL5PXVNBH5K5GH5DAIL6WGOTVAI2NFD3HLFAXHD57OG7KU5TSZBE4OLLA5A",
  "type": "Microsoft.MarketplaceOrdering/offertypes"
}
$ 
```

Para aceptarlos y tener disponible la imagen para desplegar:

```console
$ az vm image accept-terms --urn cognosys:centos-8-stream-free:centos-8-stream-free:1.2019.0810
This command has been deprecated and will be removed in version '3.0.0'. Use 'az vm image terms accept' instead.
{
  "accepted": true,
  "id": "/subscriptions/b12b6cba-621c-4f49-8a70-a7f2e2f233ea/providers/Microsoft.MarketplaceOrdering/offerTypes/Microsoft.MarketplaceOrdering/offertypes/publishers/cognosys/offers/centos-8-stream-free/plans/centos-8-stream-free/agreements/current",
  "licenseTextLink": "https://storelegalterms.blob.core.windows.net/legalterms/3E5ED_legalterms_COGNOSYS%253a24CENTOS%253a2D8%253a2DSTREAM%253a2DFREE%253a24CENTOS%253a2D8%253a2DSTREAM%253a2DFREE%253a24CCYSNQWELVORSIA5MDTVHE6FPIZ5GCO3T6OUM53IUP4XFKJY2B4QTN6L43QJMNSF7SRMTP24UPT5LWRG35IQ7SJVHFMLGFEXMXKVQGI.txt",
  "name": "centos-8-stream-free",
  "plan": "centos-8-stream-free",
  "privacyPolicyLink": "http://www.cogno-sys.com/cognosys-technologies-partners/privacy-policy/",
  "product": "centos-8-stream-free",
  "publisher": "cognosys",
  "retrieveDatetime": "2021-02-07T11:06:35.6563039Z",
  "signature": "4W54BQRPTRPHMJQ3YRBA4B5MRWDYF7LTDDQ7YLVOVTG3L5KXTPSFXGILYSSJDDPEROAYIQJZX6Q2IUXHU3WBHJ4FEGSDNV7ANML7GXI",
  "type": "Microsoft.MarketplaceOrdering/offertypes"
}
$ 
```

En el código de Terraform para crear una máquina virtual a partir de esta imagen deberemos incluir:

```terraform
    plan {
        name      = "centos-8-stream-free"
        product   = "centos-8-stream-free"
        publisher = "cognosys"
    }

    source_image_reference {
        publisher = "cognosys"
        offer     = "centos-8-stream-free"
        sku       = "centos-8-stream-free"
        version   = "1.2019.0810"
    }
```