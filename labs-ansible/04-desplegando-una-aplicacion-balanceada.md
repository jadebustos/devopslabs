# Desplegando una aplicación balanceada

Vamos a desplegar una aplicación balanceada con ansible. Para ello desplegaremos utilizando ansible:

+ Un haproxy.
+ Dos servidores web apache.
+ Desplegaremos la aplicación web en los servidores apache.
+ Configuraremos el balanceo en el haproxy para la aplicación balanceada.

Para ello necesitaremos tener desplegado:

+ Una máquina para desplegar el balanceador haproxy.
+ Dos máquinas para desplegar los servidores web apache.
+ Una máquina que hará de controller de ansible que utilizaremos para ejecutar los playbooks de ansible y desplegar la aplicación.

## Configurando el entorno para la ejecución de tareas con ansible

En el nodo controller necesitaremos tener instalado ansible.

También necesitaremos crear un usuario no-root, deberemos crear en este usuario unas [claves ssh](00-primeros-pasos.md).

En los nodos en los que vamos a ejecutar tareas, donde desplegaremos el haproxy y los balanceadores, necesitamos crear un usuario no privilegiado y añadir la clave pública del usuario en el nodo controller de ansible que ejecutará los playbooks de ansible y configurar ese usuario para que pueda hacer escalado de privilegios. Todo esto se encuentra explicado [00-primeros-pasos.md](00-primeros-pasos.md).

## Creación del inventario

Lo primero que tendremos que hacer es crear un inventario con varios grupos. Los grupos se utilizarán para agrupar las máquinas en las que vamos a desplegar la aplicación  según las tareas a realizar. Incluiremos en cada grupo todas las máquinas en las que tendremos que realizar tareas comunes.

En este caso tendremos dos grupos, uno para las tareas a realizar en el haproxy, y otro para las tareas a realizar en los servidores apache:

```ini
[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_user=executor

[haproxy]
haproxy.acme.es

[apache]
apache1.acme.es 
apache2.acme.es
```

> ![IMPORTANT](../imgs/important-icon.png) En estos ejemplos utilizaremos el inventario anterior y no el presente en el directorio. El que hay en el directorio contiene grupos para desplegar la aplicación sobre un grupo de servidores de la familia Red Hat o bien Debian.

> ![TIP](../imgs/tip-icon.png) Si necesitaramos ejecutar tareas comunes en todos los nodos podemos añadir un grupo adicional con todos los servidores:
>
>```ini
>[all:vars]
>ansible_python_interpreter=/usr/bin/python3
>ansible_user=executor
>
>[haproxy]
>haproxy.acme.es
>
>[apache]
>apache1.acme.es 
>apache2.acme.es
>
>[webapp]
>haproxy.acme.es
>apache1.acme.es 
>apache2.acme.es
>```

Para comprobar que ansible puede conectarse a los nodos y ejecutar tareas haremos lo siguiente:

```console
[jadebustos@archimedes labs-ansible]$ ansible -i hosts -m ping all
haproxy.acme.es | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
worker01.acme.es | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
worker02.acme.es | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
[jadebustos@archimedes labs-ansible]$
```

> ![TIP](../imgs/tip-icon.png) En el fichero de inventario podemos utilizar FQDN o direcciones IP. Si utilizamos FQDN deberemos poder resolverlas, bien vía DNS o el fichero **/etc/hosts** en Linux o en el fichero **C:\Windows\System32\drivers\etc\hosts** en Windows.

Con esto hemos verificado que ansible puede ejecutar tareas en los hosts. Si necesitamos realizar escalado de privilegios para ejecutar las tareas podemos comprobar que la configuración es correcta si nos conectamos a las máquinas con el usuario que utilizará ansible y podemos ejecutar **sudo su -** de forma satisfactoria sin facilitar contraseña:

```console
[jadebustos@archimedes azure]$ ssh executor@haproxy.acme.es
Last login: Sun Feb  7 17:27:52 2021 from 192.168.1.46
[executor@haproxy ~]$ sudo su -
[root@haproxy ~]# 
```

## Desplegando la aplicación

Para desplegar la aplicación deberemos realizar varias tareas:

+ Desplegar y configurar el balanceador.
+ Desplegar Apache.
+ Desplegar la aplicación.

Para cada una de estas tareas utilizaremos un playbook de ansible.

## Desplegando y configurando haproxy

Para desplegar el haproxy ejecutaremos el playbook [deploy-haproxy.yaml](deploy-haproxy.yaml) sobre el grupo del inventario del haproxy:

```console
[jadebustos@archimedes ansible]$ ansible-playbook -i hosts -l haproxy deploy-haproxy.yaml
```

El playbook:

```yaml
---

- name: deploy haproxy
  hosts: all
  vars_files:
    - "group_vars/haproxy.yaml"
  gather_facts: true
  roles:
    - haproxy
```

+ **name** se utiliza para dar un nombre descriptivo a la tarea.
+ **hosts** se puede utilizar para restringir su ejecución a un grupo de equipos en el inventario. En este caso no ponemos ninguna limitación sobre el grupo de equipos en el que se ejecutará y lo haremos en los parámetros en la ejecución del playbook.
+ **vars_files** define los ficheros de variables que utilizará el playbook. Si incluimos como variables los datos que pueden cambiar en diferentes instalaciones, como ips, hostnames, ... será muy fácil reutilizar el código.
+ **gather_facts** indica si se deben recoger facts o no del equipo donde se va a ejecutar la tarea. En estos playbooks se comprueba si la máquina en la que se va a ejecutar es de la familia Red Hat o Debian y dependiendo de que familia sea ejecutará unas tareas u otras. Esto lo utilizaremos cuando haya tareas que dependan del Sistema Operativo, como instalar paquetes.
+ **roles** indica los roles que se van a ejecutar.

El playbook ejecuta el role **haproxy**. La estructura del role es la siguiente:

```console
[jadebustos@archimedes labs-ansible]$ tree roles/haproxy/
roles/haproxy/
├── files
│   ├── acme.es.pem
│   └── cacert.pem
├── tasks
│   ├── 01-install.yaml
│   ├── 02-services.yaml
│   ├── 03-firewall.yaml
│   └── main.yaml
└── templates
    └── haproxy.cfg.j2

3 directories, 7 files
[jadebustos@archimedes labs-ansible]$
```

+ El directorio **files** contiene ficheros que se copiaran a la máquina sobre la que se ejecute la tarea. Se utilizará el módulo de ansible [copy](https://docs.ansible.com/ansible/2.9/modules/copy_module.html).
+ El directorio **templates** contiene los [templates jinja2](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html) que se utilizarán para generar ficheros evitando hardcodear datos y basándose en valores de variables. Estos ficheros se generarán con el módulo de ansible [template](https://docs.ansible.com/ansible/2.9/modules/template_module.html).
+ El directorio **tasks** incluirá las tareas ansible a realizar. Se pueden incluir todas en el fichero **main.yaml** pero es buena práctica el agrupar las tareas relacionadas en ficheros yaml independientes e incluirlas en el fichero **main.yaml**.

## Desplegando Apache

Una vez desplegado el haproxy es necesario instalar los apache y para ello ejecutaremos el playbook [deploy-httpd.yaml](deploy-httpd.yaml):

```console
[jadebustos@archimedes ansible]$ ansible-playbook -i hosts -l apache deploy-httpd.yaml
```

El playbook:

```yaml
---

- name: deploy httpd servers
  hosts: all
  vars_files:
    - "group_vars/httpd.yaml"
  gather_facts: true
  roles:
    - httpd
```

El playbook ejecuta el role **httpd**. La estructura del role es la siguiente:

```console
[jadebustos@archimedes labs-ansible]$ tree roles/httpd/
roles/httpd/
└── tasks
    ├── 01-install.yaml
    ├── 02-services.yaml
    ├── 03-firewall.yaml
    └── main.yaml

1 directory, 4 files
[jadebustos@archimedes labs-ansible]$ 
```

En este caso el role solo contiene tareas.

## Desplegando la aplicación

Una vez desplegado el haproxy es necesario instalar los apache y para ello ejecutaremos el playbook [deploy-webapp.yaml](deploy-webapp.yaml):

```console
[jadebustos@archimedes ansible]$ ansible-playbook -i hosts -l apache deploy-webapp.yaml
```

El playbook:

```yaml
---

- name: deploy webapp
  hosts: all
  vars_files:
    - "group_vars/webapp.yaml"
  gather_facts: true
  roles:
    - webapp
```

El playbook ejecuta el role **webapp**. La estructura del role es la siguiente:

```console
[jadebustos@archimedes labs-ansible]$ tree roles/webapp/
roles/webapp/
├── files
│   ├── acme.es.crt
│   ├── acme.es.key
│   └── cacert.pem
├── tasks
│   ├── 01-webapp.yaml
│   └── main.yaml
└── templates
    ├── devops.conf.j2
    └── index.html.j2

3 directories, 7 files
[jadebustos@archimedes labs-ansible]$ 
```