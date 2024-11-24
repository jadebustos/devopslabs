# Deploying a load balanced applications

You will deploy a load balanced application using ansible. So you eill deploy:

+ An haproxy server.
+ Two apache servers.
+ Web application will be deployed on the apache servers.
+ Haproxy configuration to load balance the aplication will be deployed using ansible as well.

The following VMs will be needed:

+ A VM to deploy the haproxy server.
+ Two VMs to deploy the apache servers.
+ One ansible controller.

As you have already deployed an ansible controller you will only have to deploy three more Centos Stream 9 VMs and configure them so ansible can execute tasks on them as root user, in the same way you did with the ansible client node.

## Inventory

You will create an inventory with two groups. One for the haproxy and the other group to configure the apache servers:

```ini
[all:vars]
ansible_user=ansible

[haproxy]
haproxy.melmac.univ

[apache]
apache1.melmac.univ 
apache2.melmac.univ
```

Para comprobar que ansible puede conectarse a los nodos y ejecutar tareas haremos lo siguiente:

```console
[ansible@controller wrkshp-ansible]$ ansible -i hosts -m ping all





[ansible@controller wrkshp-ansible]$
```

> ![TIP](../imgs/tip-icon.png) In the inventory file you can use FQDN or IP addresses.

## haproxy deployment

Para desplegar el haproxy ejecutaremos el playbook [deploy-haproxy.yaml](deploy-haproxy.yaml) sobre el grupo del inventario del haproxy:

```console
[ansible@controller ansible]$ ansible-playbook -i hosts -l haproxy deploy-haproxy.yaml
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
[ansible@controller wrkshp-ansible]$ tree roles/haproxy/
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
[ansible@controller wrkshp-ansible]$
```

+ El directorio **files** contiene ficheros que se copiaran a la máquina sobre la que se ejecute la tarea. Se utilizará el módulo de ansible [copy](https://docs.ansible.com/ansible/2.9/modules/copy_module.html).
+ El directorio **templates** contiene los [templates jinja2](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html) que se utilizarán para generar ficheros evitando hardcodear datos y basándose en valores de variables. Estos ficheros se generarán con el módulo de ansible [template](https://docs.ansible.com/ansible/2.9/modules/template_module.html).
+ El directorio **tasks** incluirá las tareas ansible a realizar. Se pueden incluir todas en el fichero **main.yaml** pero es buena práctica el agrupar las tareas relacionadas en ficheros yaml independientes e incluirlas en el fichero **main.yaml**.

## Desplegando Apache

Una vez desplegado el haproxy es necesario instalar los apache y para ello ejecutaremos el playbook [deploy-httpd.yaml](deploy-httpd.yaml):

```console
[ansible@controller ansible]$ ansible-playbook -i hosts -l apache deploy-httpd.yaml
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
[ansible@controller wrkshp-ansible]$ tree roles/httpd/
roles/httpd/
└── tasks
    ├── 01-install.yaml
    ├── 02-services.yaml
    ├── 03-firewall.yaml
    └── main.yaml

1 directory, 4 files
[ansible@controller wrkshp-ansible]$ 
```

En este caso el role solo contiene tareas.

## Desplegando la aplicación

Una vez desplegado el haproxy es necesario instalar los apache y para ello ejecutaremos el playbook [deploy-webapp.yaml](deploy-webapp.yaml):

```console
[ansible@controller ansible]$ ansible-playbook -i hosts -l apache deploy-webapp.yaml
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
[ansible@controller wrkshp-ansible]$ tree roles/webapp/
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
[ansible@controller wrkshp-ansible]$ 
```