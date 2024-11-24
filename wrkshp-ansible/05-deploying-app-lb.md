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

## Haproxy deployment

Para desplegar el haproxy ejecutaremos el playbook [deploy-haproxy.yaml](deploy-haproxy.yaml) sobre el grupo del inventario del haproxy:

```console
[ansible@controller ansible]$ ansible-playbook -i hosts -l haproxy deploy-haproxy.yaml
```

[deploy-haproxy.yaml](deploy-haproxy.yaml) playbook:

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

**haproxy** role infrastructure:

```console
[ansible@controller wrkshp-ansible]$ tree roles/haproxy/




[ansible@controller wrkshp-ansible]$
```

## Apache deployment

Once haproxy has been deployed you need to deploy the apache servers:

```console
[ansible@controller ansible]$ ansible-playbook -i hosts -l apache deploy-httpd.yaml
```

[deploy-httpd.yaml](deploy-httpd.yaml) playbook:


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

**apache** role infrastructure:

```console
[ansible@controller wrkshp-ansible]$ tree roles/httpd/




[ansible@controller wrkshp-ansible]$ 
```

## Application deployment

To deploy the application:

```console
[ansible@controller ansible]$ ansible-playbook -i hosts -l apache deploy-webapp.yaml
```

[deploy-webapp.yaml](deploy-webapp.yaml) playbook:

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

**webapp** role infrastructure:

```console
[ansible@controller wrkshp-ansible]$ tree roles/webapp/

[ansible@controller wrkshp-ansible]$ 
```