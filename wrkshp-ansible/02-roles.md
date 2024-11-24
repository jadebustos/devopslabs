# Ansible roles

[Ansible roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) are a medium to "group" your code to be reusable in an easy and simple way.

To reuse code is mandatory not to hadcode data on your playbooks. All data related to the environment where you want to execute your code MUST be present in variables outside the code.

Doing it this way, we can reuse the ansible roles in an easy way. Changing the variables according the environment we can use the same code in different environments.

## Ansible role estructure

Ansible roles have a defined directory structure:

```
rroles/
    common/               
        tasks/            
            main.yml      
        handlers/         
            main.yml      
        templates/        
            ntp.conf.j2   
        files/            
            bar.txt       
            foo.sh        
        vars/             
            main.yml      
        defaults/         
            main.yml      
        meta/             
            main.yml      
```

Ansible roles are included in the **roles** directory. The first directory inside the **roles** directory will be the name of the role and inside this directory will be some other directories. The only mandatory directory is the **tasks** directory.

The most used directories are:

+ **tasks**, all tasks that the role must execute will be included in this directory. They must be included in the  **main.yaml** file (or **main.yml**).
+ **files**, all the files that the role must copy to the ansible clients.
+ **templates**, file templates to copy to ansible clients. These files will be customized based on variable values.
* **vars**, variables used by the ansible role.

## Ansible playbook using roles

You are going to create an ansible playbook using roles.

You will create a role which will create users and the password for the users will be configured as well. You will create two roles:

1. One role to create users.
2. Another role to configure user password.

> ![IMPORTANT](../imgs/important-icon.png) Once the users are create we will need to assign the password, not only when the users were created. Users can ask for a password change due to they forgot it. In this case the system admins will only need to use the role for password change. Two use case are covered, initial users creation and user password changes.

You will create a file containing user data. This file will be placed in the [group_vars/users.yaml](group_vars/users.yaml). As the user data will be used by two different roles we will use this directory instead of the **vars** directory in the ansible role directory structure:

```yaml
---

# user information. Data is stored using a dictionary
users:
  operator:
    password: 'temporal123'
    home: '/home/operator'
    gecos: 'operation user'
    shell: '/bin/bash'
    generate_ssh_keys: 'yes'
    ssh_key_size: 3072
  security:
    password: '12345'
    home: '/home/security'
    gecos: 'security user'
    shell: '/bin/bash'
    generate_ssh_keys: 'yes'
    ssh_key_size: 4096
  backup:
    password: 'password'
    home: '/var/lib/backup'
    gecos: 'backup user'
    shell: '/sbin/nologin'
    generate_ssh_keys: 'no'
    ssh_key_size: 0
  monitoring:
    password: 'monitoring'
    home: '/var/lib/monitoring'
    gecos: 'monontoring user'
    shell: '/sbin/nologin'
    generate_ssh_keys: 'no'
    ssh_key_size: 0
```

> ![IMPORTANT](../imgs/important-icon.png) Password is in plain text in this example. This is not a best practice. You will see how address this issue later.

You will create an ansible role named **users**:

```console
[ansible@controller ~]$ mkdir -p homework/roles
[ansible@controller ~]$ cd homework/roles/
[ansible@controller roles]$ ansible-galaxy init users
- Role users was created successfully
[ansible@controller roles]$ tree users/
users/
├── defaults
│   └── main.yml
├── files
├── handlers
│   └── main.yml
├── meta
│   └── main.yml
├── README.md
├── tasks
│   └── main.yml
├── templates
├── tests
│   ├── inventory
│   └── test.yml
└── vars
    └── main.yml

8 directories, 8 files
[ansible@controller roles]$ 
```

File [roles/users/tasks/main.yaml](roles/users/tasks/main.yaml) includes all tasks to be performed by the role:

```yaml
---

- include_tasks: 01-create.yaml
```

We can organize the role tasks in different files such [roles/users/tasks/01-create.yaml](roles/users/tasks/01-create.yaml) and including them in the [roles/users/tasks/main.yaml](roles/users/tasks/main.yaml) file:

```yaml
---

- name: create users
  ansible.builtin.user:
    name: "{{ item.key }}"
    comment: "{{ item.value.gecos }}"
    home: "{{ item.value.home }}"
    shell: "{{ item.value.shell }}"
    generate_ssh_key: "{{ item.value.generate_ssh_keys }}"
    ssh_key_bits: "{{ item.value.ssh_key_size }}"
  become: true
  loop: "{{ users | dict2items }}"
```

Iteration will be done over the dictionary **users** using the dictionary keys (**operator**, **security**, **backup** y **monitoring**) where:

+ **ansible.builtin.user** ansible module for user creation. Ansible module [user](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/user_module.html) will create the users.
+ **item.key** dictionary key used to iterate, username.
+ **item.value.gecos** gecos value for the key being iterated.
+ **item.value.home** home value for the key being iterated.
+ **item.value.shell** shell value for the key being iterated.
+ **item.value.generate_ssh_keys** generate_ssh_keys value for the key being iterated.
+ **item.value.ssh_key_bits** ssh_key_bits value for the key being iterated.
+ **become: true** tells ansible that the task must be executed as **root**.
+ **loop** [dictionary iteration](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_loops.html#iterating-over-a-dictionary).

> ![IMPORTANT](../imgs/important-icon.png) **"{{ variable }}"** means using an ansible variable.

Users will be created but they will not have a password configured. You will create a new role to configure user's passwords.

Ansible role to configure user's passwords:

```console
[ansible@controller wrkshp-ansible]$ tree roles/passwd/
roles/passwd/
└── tasks
    ├── 01-password.yaml
    └── main.yaml

1 directory, 2 files
[ansible@controller wrkshp-ansible]$
```
File [roles/passwd/tasks/main.yaml](roles/passwd/tasks/main.yaml) includes all tasks to be performed by the role:

```yaml
---

- include_tasks: 01-password.yaml
```

We can organize the role tasks in different files such [roles/users/tasks/01-password.yaml](roles/users/tasks/01-password.yaml) and including them in the [roles/passwd/tasks/main.yaml](roles/passwd/tasks/main.yaml) file:

```yaml
---

# create users's password hash and store it in a variable
- name: generate sha512 password hashes
  ansible.builtin.shell: "/usr/bin/openssl passwd -6 -salt $(/usr/bin/openssl rand -base64 48) {{ item.value.password }}"
  register: sha512
  with_dict:
    - "{{ users }}"

#- name: display sha512
#  ansible.builtin.debug: var=sha512

#- name: show sha512.results
#  ansible.builtin.debug: var=item.stdout
#  loop:
#    - "{{ sha512.results }}"

# create a dictionary where the key is the username and the value is password's hash
# to see sha512 structure you can uncomment the two above tasks
- name: create a dictionary with password hashes
  set_fact:
    passwdhashes: "{{ passwdhashes|default({}) | combine( {item.item.key: item.stdout} ) }}"
  loop: "{{ sha512.results }}"

# uncomment this task to see passwordhasses structure
#- name: display passwordhashes
#  ansible.builtin.debug: var=passwdhashes

# configure user's passwords
- name: change shadow password hash
  ansible.builtin.user:
    user: "{{ item.key }}"
    password: "{{ item.value }}"
  become: yes
  with_dict:
    - "{{ passwdhashes }}"
```

+ First task iterates over the **users** dictionary, runs a command to print tha password's hash (sha512) and store it in the **sha512** var. The next two tasks are commented, if you uncomment them **sha512** variable will be printed on the screen.

+ The following task iterates over the results from the first tasks which were stored into the var **sha512.results**. A new dictionary will be created, user's name will be the key and the user's password hash the value.

+ Next task prints the created dictionary.

+ Last task iterates over the dictionary **passwdhashes** and changes user's passwords.

Now, we have two roles, one to create users and the second one to change user's passwords. To create the users you will need to create an ansible playbook and use these roles. The playbook [create-users.yaml](create-users.yaml) will do the job.

```yaml
---

- name: create users
  hosts: all
  vars_files:
    - "group_vars/users.yaml"
  gather_facts: false
  roles:
    - users
    - passwd
```

+ **hosts** is used to tell ansible in which inventory nodes the playbook will be executed. This is mandatory an can be overwritten using the **ansible-playbook's** command line arguments.
+ **vars_files** list with variable files which are not in the role's var directory.
+ **gather_facts** is used to tell ansible to gather information about the system in which is running a task. This information is stored in variables and can be used for ansible to perform tasks. You will learn a bit more on [04-facts-ansible.md](04-facts-ansible.md).
+ **roles** list of roles to use.

To run the playbook:

```console
[ansible@controller wrkshp-ansible]$ ansible-playbook -i hosts -l client create-users.yaml 
...
[ansible@controller wrkshp-ansible]$ 
```
> ![TIP](../imgs/tip-icon.png) Using the **-l** flag we can restrict the execution to a subset of inventory members, in this case the playbook will only be execute on the **client** group.

## Improvements

Use plain text for passwords is not a best practice. Not only passwords will be available for all those have access to the repository where the code is stored but passwords will be printed on the ansible output as well.

Confidential data must be included in **vaults**. In [06-protecting-sensitive-information.md](06-protecting-sensitive-information.md) you can see how to use the ansible's vault.

> ![TIP](../imgs/tip-icon.png) Commercial vaults can also be used together with ansible.

## Resources

* [Ansible Roles](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html)
* [Ansible Galaxy](https://docs.ansible.com/ansible/latest/cli/ansible-galaxy.html)
* [Ansible user module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/user_module.html). And now you know where look for information about ansible modules and where to look for ansible modules as well.
* [Ansible loops](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_loops.html#iterating-over-a-dictionary)