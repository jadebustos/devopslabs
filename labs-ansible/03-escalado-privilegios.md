# Escalado de privilegios

## Escalando privilegios para varias tareas a la vez

En lugar de ir especificando **become: true** tarea a tarea es posible hacerlo de tal forma que solo se indique una vez.

Podemos indicar en el playbook que todas las tareas se ejecuten con escalado de privilegios:

```yaml
- name: ejemplo de escalación de privilegios para todas las tareas
  hosts: all
  become: true  
  gather_facts: false
  roles:
    - role1
    - role2
```

En el ejemplo anterior todas las tareas incluidas en el playbook, las incluidas en los roles **role1** y **role2**, se ejecutarán como root. Si en lugar de roles hubieramos incluido tareas directamente el resultado será el mismo.

En el caso de que no todas las tareas se necesiten ejecutar como root:

```yaml
- name:  ejemplo de escalación de privilegios para todas las tareas
  hosts: all
  gather_facts: false
  roles:
    - { role: role1, become: yes }
    - role2
```

En el ejemplo anterior todas las tareas del **role1** se ejecutaran como root mientras que las del **role2** no.

También podemos utilizar **block** para agrupar las tareas a ejecutar como root:

```yaml
- block:
    - name: instalar paquetes
      dnf:
        name: ['gcc', 'make']
        state: present
    - name: añadir línea a /etc/hosts
      lineinfile:
        path: /etc/hosts
        line: "192.168.1.200 myhost.mydomain"
        state: present
  become: yes
```

## Ejecución de tareas como otro usuario

Es posible impersonar a otros usuarios, no solo al usuario root. Para ellos bastará añadir **become_user: usuario** junto a **become: true** para ejecutar la tarea o grupo de tareas como dicho usuario.