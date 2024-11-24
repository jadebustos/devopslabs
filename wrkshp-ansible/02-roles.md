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
  with_dict:
    - "{{ users }}"
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
+ **with_dict** dictionary iteration.

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

 create users's password hash and store it in a variable
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

+ La primera tarea itera sobre el diccionario **users**, ejecuta un comando que imprime en la salida estándar el hash (sha512) de la contraseña y almacena estas salidas en la variable **sha512**. Si se descomentan las dos tareas siguientes se imprimirá en pantalla lo almacenado en la variable **sha512**. Nos permitirá ver su estructura para ser utilizada en la siguiente tarea.

+ La siguiente tarea itera sobre los resultados obtenidos en la ejecución de la primera tarea y que se encuentran almacenados en **sha512.results**. Se creará un diccionario cuya clave serán los nombres de los usuarios y el valor el hash (sha512) de la contraseña de ese usuario.

+ La siguiente tarea imprime el diccionario creado.

+ La última tarea itera sobre el diccionario que hemos creado, **passwdhashes** y cambia la contraseña de los usuarios.

Ya tenemos los roles, ahora será necesario crear un playbook que los use para crear los usuarios y asignarles las contraseñas.

El playbook en cuestion será [create-users.yaml](create-users.yaml):

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

+ **hosts** indica sobre que elementos del inventario se ejecutará el playbook.
+ **vars_files** es una lista que incluye los ficheros de variables. Vamos a utilizar el mismo fichero de variables para ambos roles y hemos optado por utilizar un fichero externo al módulo para almacenar las variables.
+ **gather_facts** se utiliza para que ansible recoga información de la máquina donde va a ejecutar la tarea. Esa información se almacenará en variables, llamadas **facts**, y podrá ser utilizada en el playbook. En este caso como no se necesita esa información no se recoge ya que dicha recolección consume tiempo. Para más información ver [04-facts-ansible.md](04-facts-ansible.md).
+ **roles** es una lista que incluye los roles a ejecutar por el playbook. Estos roles se ejecutarán en el orden en que aparecen indicados.

Para ejecutarlo:

```console
[jadebustos@ansiblectrl labs-ansible]$ ansible-playbook -i hosts -l client create-users.yaml 

PLAY [create users] **************************************************************************************************************************************************************************************************************************

TASK [users : include_tasks] *****************************************************************************************************************************************************************************************************************
included: /home/jadebustos/devopslabs/labs-ansible/roles/users/tasks/01-create.yaml for ansibleclient.jadbp.lab

TASK [create users] **************************************************************************************************************************************************************************************************************************
changed: [ansibleclient.jadbp.lab] => (item={'key': 'operator', 'value': {'password': 'temporal123', 'home': '/home/operator', 'gecos': 'usuario para tareas de operacion', 'shell': '/bin/bash', 'generate_ssh_keys': 'yes', 'ssh_key_size': 3072}})
changed: [ansibleclient.jadbp.lab] => (item={'key': 'security', 'value': {'password': '12345', 'home': '/home/security', 'gecos': 'usuario de seguridad', 'shell': '/bin/bash', 'generate_ssh_keys': 'yes', 'ssh_key_size': 4096}})
changed: [ansibleclient.jadbp.lab] => (item={'key': 'backup', 'value': {'password': 'password', 'home': '/var/lib/backup', 'gecos': 'usuario para ejecutar el agente de backup', 'shell': '/sbin/nologin', 'generate_ssh_keys': 'no', 'ssh_key_size': 0}})
changed: [ansibleclient.jadbp.lab] => (item={'key': 'monitoring', 'value': {'password': 'enunlugardelamancha', 'home': '/var/lib/monitoring', 'gecos': 'usuario para ejecutar el agente de monitorizacion', 'shell': '/sbin/nologin', 'generate_ssh_keys': 'no', 'ssh_key_size': 0}})

TASK [passwd : include_tasks] ****************************************************************************************************************************************************************************************************************
included: /home/jadebustos/devopslabs/labs-ansible/roles/passwd/tasks/01-password.yaml for ansibleclient.jadbp.lab

TASK [passwd : generate sha512 password hashes] **********************************************************************************************************************************************************************************************
changed: [ansibleclient.jadbp.lab] => (item={'key': 'operator', 'value': {'password': 'temporal123', 'home': '/home/operator', 'gecos': 'usuario para tareas de operacion', 'shell': '/bin/bash', 'generate_ssh_keys': 'yes', 'ssh_key_size': 3072}})
changed: [ansibleclient.jadbp.lab] => (item={'key': 'security', 'value': {'password': '12345', 'home': '/home/security', 'gecos': 'usuario de seguridad', 'shell': '/bin/bash', 'generate_ssh_keys': 'yes', 'ssh_key_size': 4096}})
changed: [ansibleclient.jadbp.lab] => (item={'key': 'backup', 'value': {'password': 'password', 'home': '/var/lib/backup', 'gecos': 'usuario para ejecutar el agente de backup', 'shell': '/sbin/nologin', 'generate_ssh_keys': 'no', 'ssh_key_size': 0}})
changed: [ansibleclient.jadbp.lab] => (item={'key': 'monitoring', 'value': {'password': 'enunlugardelamancha', 'home': '/var/lib/monitoring', 'gecos': 'usuario para ejecutar el agente de monitorizacion', 'shell': '/sbin/nologin', 'generate_ssh_keys': 'no', 'ssh_key_size': 0}})

TASK [passwd : create a dictionary with password hashes] *************************************************************************************************************************************************************************************
ok: [ansibleclient.jadbp.lab] => (item={'cmd': 'openssl passwd -6 -salt $(openssl rand -base64 48) temporal123', 'stdout': '$6$ij43auXpmyXRLoE9$iUfipM2kJ5gSHm7ZA5gt/EzmyyiRfS5g83TkqgWYAlLXk4A5MPzib7Vlbv2QilbRBJlbgSQ3lQSC.VWS6g4m9.', 'stderr': '', 'rc': 0, 'start': '2021-06-19 18:33:32.403393', 'end': '2021-06-19 18:33:32.423792', 'delta': '0:00:00.020399', 'changed': True, 'invocation': {'module_args': {'_raw_params': 'openssl passwd -6 -salt $(openssl rand -base64 48) temporal123', '_uses_shell': True, 'warn': True, 'stdin_add_newline': True, 'strip_empty_ends': True, 'argv': None, 'chdir': None, 'executable': None, 'creates': None, 'removes': None, 'stdin': None}}, 'stdout_lines': ['$6$ij43auXpmyXRLoE9$iUfipM2kJ5gSHm7ZA5gt/EzmyyiRfS5g83TkqgWYAlLXk4A5MPzib7Vlbv2QilbRBJlbgSQ3lQSC.VWS6g4m9.'], 'stderr_lines': [], 'failed': False, 'item': {'key': 'operator', 'value': {'password': 'temporal123', 'home': '/home/operator', 'gecos': 'usuario para tareas de operacion', 'shell': '/bin/bash', 'generate_ssh_keys': 'yes', 'ssh_key_size': 3072}}, 'ansible_loop_var': 'item'})
ok: [ansibleclient.jadbp.lab] => (item={'cmd': 'openssl passwd -6 -salt $(openssl rand -base64 48) 12345', 'stdout': '$6$CkeoaArQPwNKncGy$SvxF3U/vRX/v.DSnI532csnSIKz2/gf.UHDi/QB.SDuSh1WCKDncw.ue7yisGEaVg6ekzsBfil067X0KTS8ho.', 'stderr': '', 'rc': 0, 'start': '2021-06-19 18:33:33.131178', 'end': '2021-06-19 18:33:33.152753', 'delta': '0:00:00.021575', 'changed': True, 'invocation': {'module_args': {'_raw_params': 'openssl passwd -6 -salt $(openssl rand -base64 48) 12345', '_uses_shell': True, 'warn': True, 'stdin_add_newline': True, 'strip_empty_ends': True, 'argv': None, 'chdir': None, 'executable': None, 'creates': None, 'removes': None, 'stdin': None}}, 'stdout_lines': ['$6$CkeoaArQPwNKncGy$SvxF3U/vRX/v.DSnI532csnSIKz2/gf.UHDi/QB.SDuSh1WCKDncw.ue7yisGEaVg6ekzsBfil067X0KTS8ho.'], 'stderr_lines': [], 'failed': False, 'item': {'key': 'security', 'value': {'password': '12345', 'home': '/home/security', 'gecos': 'usuario de seguridad', 'shell': '/bin/bash', 'generate_ssh_keys': 'yes', 'ssh_key_size': 4096}}, 'ansible_loop_var': 'item'})
ok: [ansibleclient.jadbp.lab] => (item={'cmd': 'openssl passwd -6 -salt $(openssl rand -base64 48) password', 'stdout': '$6$U5z8jT1Wnkbpm1Zc$.IA0mVtGaDnv7p49X6AVR9Mp65cICvB2FIUKssct51dm92ejWo61hMicaGW9Eh9IjgRuHWFROFdt.er0NKpll.', 'stderr': '', 'rc': 0, 'start': '2021-06-19 18:33:33.847984', 'end': '2021-06-19 18:33:33.867853', 'delta': '0:00:00.019869', 'changed': True, 'invocation': {'module_args': {'_raw_params': 'openssl passwd -6 -salt $(openssl rand -base64 48) password', '_uses_shell': True, 'warn': True, 'stdin_add_newline': True, 'strip_empty_ends': True, 'argv': None, 'chdir': None, 'executable': None, 'creates': None, 'removes': None, 'stdin': None}}, 'stdout_lines': ['$6$U5z8jT1Wnkbpm1Zc$.IA0mVtGaDnv7p49X6AVR9Mp65cICvB2FIUKssct51dm92ejWo61hMicaGW9Eh9IjgRuHWFROFdt.er0NKpll.'], 'stderr_lines': [], 'failed': False, 'item': {'key': 'backup', 'value': {'password': 'password', 'home': '/var/lib/backup', 'gecos': 'usuario para ejecutar el agente de backup', 'shell': '/sbin/nologin', 'generate_ssh_keys': 'no', 'ssh_key_size': 0}}, 'ansible_loop_var': 'item'})
ok: [ansibleclient.jadbp.lab] => (item={'cmd': 'openssl passwd -6 -salt $(openssl rand -base64 48) enunlugardelamancha', 'stdout': '$6$X9az2GQgxx9ZnHT/$avyQE29t.0VTP9ADJ98QuRpZHAiPVS/qVo/c4jH.mVAFkSPupGuwgo2z0EFs5msPtZz4hD8wZuuwexJ0zlQ7l0', 'stderr': '', 'rc': 0, 'start': '2021-06-19 18:33:34.582198', 'end': '2021-06-19 18:33:34.603799', 'delta': '0:00:00.021601', 'changed': True, 'invocation': {'module_args': {'_raw_params': 'openssl passwd -6 -salt $(openssl rand -base64 48) enunlugardelamancha', '_uses_shell': True, 'warn': True, 'stdin_add_newline': True, 'strip_empty_ends': True, 'argv': None, 'chdir': None, 'executable': None, 'creates': None, 'removes': None, 'stdin': None}}, 'stdout_lines': ['$6$X9az2GQgxx9ZnHT/$avyQE29t.0VTP9ADJ98QuRpZHAiPVS/qVo/c4jH.mVAFkSPupGuwgo2z0EFs5msPtZz4hD8wZuuwexJ0zlQ7l0'], 'stderr_lines': [], 'failed': False, 'item': {'key': 'monitoring', 'value': {'password': 'enunlugardelamancha', 'home': '/var/lib/monitoring', 'gecos': 'usuario para ejecutar el agente de monitorizacion', 'shell': '/sbin/nologin', 'generate_ssh_keys': 'no', 'ssh_key_size': 0}}, 'ansible_loop_var': 'item'})

TASK [passwd : display passwordhashes] *******************************************************************************************************************************************************************************************************
ok: [ansibleclient.jadbp.lab] => {
    "passwdhashes": {
        "backup": "$6$U5z8jT1Wnkbpm1Zc$.IA0mVtGaDnv7p49X6AVR9Mp65cICvB2FIUKssct51dm92ejWo61hMicaGW9Eh9IjgRuHWFROFdt.er0NKpll.",
        "monitoring": "$6$X9az2GQgxx9ZnHT/$avyQE29t.0VTP9ADJ98QuRpZHAiPVS/qVo/c4jH.mVAFkSPupGuwgo2z0EFs5msPtZz4hD8wZuuwexJ0zlQ7l0",
        "operator": "$6$ij43auXpmyXRLoE9$iUfipM2kJ5gSHm7ZA5gt/EzmyyiRfS5g83TkqgWYAlLXk4A5MPzib7Vlbv2QilbRBJlbgSQ3lQSC.VWS6g4m9.",
        "security": "$6$CkeoaArQPwNKncGy$SvxF3U/vRX/v.DSnI532csnSIKz2/gf.UHDi/QB.SDuSh1WCKDncw.ue7yisGEaVg6ekzsBfil067X0KTS8ho."
    }
}

TASK [passwd : change shadow password hash] **************************************************************************************************************************************************************************************************
changed: [ansibleclient.jadbp.lab] => (item={'key': 'operator', 'value': '$6$ij43auXpmyXRLoE9$iUfipM2kJ5gSHm7ZA5gt/EzmyyiRfS5g83TkqgWYAlLXk4A5MPzib7Vlbv2QilbRBJlbgSQ3lQSC.VWS6g4m9.'})
changed: [ansibleclient.jadbp.lab] => (item={'key': 'security', 'value': '$6$CkeoaArQPwNKncGy$SvxF3U/vRX/v.DSnI532csnSIKz2/gf.UHDi/QB.SDuSh1WCKDncw.ue7yisGEaVg6ekzsBfil067X0KTS8ho.'})
changed: [ansibleclient.jadbp.lab] => (item={'key': 'backup', 'value': '$6$U5z8jT1Wnkbpm1Zc$.IA0mVtGaDnv7p49X6AVR9Mp65cICvB2FIUKssct51dm92ejWo61hMicaGW9Eh9IjgRuHWFROFdt.er0NKpll.'})
changed: [ansibleclient.jadbp.lab] => (item={'key': 'monitoring', 'value': '$6$X9az2GQgxx9ZnHT/$avyQE29t.0VTP9ADJ98QuRpZHAiPVS/qVo/c4jH.mVAFkSPupGuwgo2z0EFs5msPtZz4hD8wZuuwexJ0zlQ7l0'})

PLAY RECAP ***********************************************************************************************************************************************************************************************************************************
ansibleclient.jadbp.lab    : ok=7    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

[jadebustos@ansiblectrl labs-ansible]$ 
```
> ![TIP](../imgs/tip-icon.png) Mediante el uso del flag **-l** indicamos que se restringa su ejecución sobre el grupo del inventario **local** en lugar de ejecutarlo sobre todos los equipos incluidos en el inventario. Este flag prevalece sobre lo indicado en el campo **hosts** del playbook.

## Mejoras

Ya hemos comentado que el poner en claro las contraseñas no es una buena práctica, ya no solo por le hecho de que sean accesibles por todo aquel que pueda acceder al repositorio, si no que también se puede ver la contraseña en claro en las salidas del playbook.

Los datos confidenciales se deben incluir en **vaults**. En [06-protegiendo-informacion-sensible-ansible.md](06-protegiendo-informacion-sensible-ansible.md) se puede ver como utilizar el **vault** que incorpora ansible por defecto.

> ![TIP](../imgs/tip-icon.png) También es posible utilizar vaults comerciales con ansible.

> ![HOMEWORK](../imgs/homework-icon.png) Un buen ejercicio sería transformar los roles anteriores para recuperar las contraseñas de los usuarios del vault que incluye ansible por defecto.

## Resources

* [Ansible Roles](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html)
* [Ansible Galaxy](https://docs.ansible.com/ansible/latest/cli/ansible-galaxy.html)
* [Ansible user module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/user_module.html). And now you know where look for information about ansible modules and where to look for ansible modules as well.
* [Ansible loops](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_loops.html#iterating-over-a-dictionary)