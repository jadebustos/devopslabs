# Corrección automática

Para la corección automática el repositorio deberá tener la siguiente estructura:

```console
[jadebustos@archimedes cp2]$ tree .
.
├── ansible
│   ├── deploy.sh
│   └── hosts
├── README.md
└── terraform
    ├── correccion-vars.tf
    └── credentials.tf

2 directories, 5 files
[jadebustos@archimedes cp2]$
```

## Terraform

+ Todo el código terraform se encontrará en el directorio **terraform**.

+ Será necesaria la inclusión de un fichero llamado **correccion-vars.tf** teniendo únicamente el siguiente contenido:

  ```yaml
  variable "location" {
    type = string
    description = "Región de Azure donde crearemos la infraestructura"
    default = "<YOUR REGION>" 
  }

  variable "storage_account" {
    type = string
    description = "Nombre para la storage account"
    default = "<STORAGE ACCOUNT NAME>"
  }

  variable "public_key_path" {
    type = string
    description = "Ruta para la clave pública de acceso a las instancias"
    default = "~/.ssh/id_rsa.pub" # o la ruta correspondiente
  }

  variable "ssh_user" {
    type = string
    description = "Usuario para hacer ssh"
    default = "<SSH USER>"
  }
  ```

+ Los nombres de las variables no se deben cambiar, unicamente sus valores. En la corección automática este fichero se sobreescribirá con el fichero de datos del profesor corrector.

+ Las credenciales deberán ir en un fichero llamado **credentials.tf**. Este fichero no se deberá subir al repositorio para evitar compartir las credenciales. Se puede bloquear subirlo al repositorio git incluyendolo en el fichero **.gitignore**.

  ```yaml
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
  # crea un service principal y rellena los siguientes datos para autenticar
  provider "azurerm" {
    features {}
    subscription_id = "<SUBSCRIPTION_ID>"
    client_id       = "<APP_ID>"         # se obtiene al crear el service principal
    client_secret   = "<CLIENT_SECRET>"  # se obtiene al crear el service principal
    tenant_id       = "<TENANT_ID>"      # se obtiene al crear el service principal
  }
  ```

+ Ejecutar **terraform apply** dentro del directorio **terraform** tiene que realizar el despliegue en Azure.

## Ansible

+ En el directorio **ansible** se encontrarán todos playbooks, roles e inventario necesarios para el despliegue.

+ El inventario a utilizar tiene que tener la siguiente estructura:

  ```ini
  [all:vars]
  ansible_user=<YOUR ANSIBLE USER>

  [master]
  master

  [workers]
  worker1
  worker2

  [nfs]
  nfs
  ```

    > NOTA: Se pueden añadir tantas variables como se desee, pero la variable **ansible_user** debe estar definida.

+ Se deberá incluir un script bash llamdo **deploy.sh** que se encargará de ejecutar los playbooks de ansible en el orden correcto.

+ Este script se ejecutará para realizar el despliegue de kubernetes y la aplicación.