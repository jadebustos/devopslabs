# Privilege escalation

Ansible run task with the privileges of the user used to connect to the node, but sometimes privileged access is needed. So ansible allows a task to run commands as the **root** user as long as the user is allowed to become the **root** user.

To become the **root** user **become: true** or **become: yes** are used. The first one is the preferred way.

You have already seen how to use this privilege escalation on the previous examples, [roles/users/tasks/01-create.yaml](roles/users/tasks/01-create.yaml).

## Privilege escalation for serveral tasks

When we have several tasks that need to be executed as **root** we can do without having to use become in all tasks, one by one.

For instance to run a playbook wich requires all the tasks to be executed as root:

```yaml
- name: privilege escalation for all tasks
  hosts: all
  become: true  
  gather_facts: false
  roles:
    - role1
    - role2
```

All tasks executed by the playbook will be executed as **root**, that means that the two roles used by the playbook will be executed as root.

But if we only need to execute one role as root:

```yaml
- name: privilege escalation for only one role
  hosts: all
  gather_facts: false
  roles:
    - { role: role1, become: true }
    - role2
```

In this case onle the tasks for **role1** will be executed as the **root** user.

> ![TIP](../imgs/tip-icon.png) If we had used tasks instead of roles it would have been the same configuration.

We can also use **block** to group tasks to be executed as **root**:

```yaml
- block:
    - name: rpm installation
      dnf:
        name: ['gcc', 'make']
        state: present
    - name: adding line to /etc/hosts file
      lineinfile:
        path: /etc/hosts
        line: "192.168.1.200 myhost.mydomain"
        state: present
  become: true
```

## Ejecución de tareas como otro usuario

Es posible impersonar a otros usuarios, no solo al usuario **root**. Para ellos bastará añadir **become_user: usuario** junto a **become: true** para ejecutar la tarea o grupo de tareas como dicho usuario.

> ![HOMEWORK](../imgs/homework-icon.png) Probar a ejecutar tareas utilizando [become_user](https://docs.ansible.com/ansible/2.9/user_guide/become.html).