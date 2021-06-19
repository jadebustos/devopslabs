# Roles en ansible

Los [roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) en ansible es una forma de "empaquetar" código para poder reutilizarlo de forma fácil y sencilla.

## Estructura de un role

Un role tiene definida una estructura de directorios. No es necesario incluir todos los directorios, únicamente será necesario incluir aquellos que se utilicen:

```
roles/
    common/
        tasks/
        handlers/
        library/
        files/
        templates/
        vars/
        defaults/
        meta/
```

Los roles se incluiran dentro de un directorio llamado __roles__. Dentro de este directorio se creará un directorio con el nombre del role, y dentro de el estarán los directorios que definen la estructura del role.

Los principales directorios, más utilizados, son los siguientes:

+ __tasks__, contendrá las tareas a ejecutar por el role. Deberán ir en un fichero llamado __main.yaml__.
+ __files__, contendrá ficheros que se quieran copiar a los clientes con el role de ansible.
+ __templates__, contendrá templates de ficheros que se quieran copiar a los clientes con el role de ansible.

## Mejoras

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
ok: [ansibleclient.jadbp.lab] => (item={'cmd': 'openssl passwd -6 -salt $(openssl rand -base64 48) temporal123', 'stdout': '$6$9uAMaGXrvLrvXKaB$rZ1UjoXRwK5zz/fH1U8XsacokIuOxYMGMWvGGjwbFBE3pccXSHA8ZdVAp49jlmq5Z6QG5T2rYxb3G8/cttIdk1', 'stderr': '', 'rc': 0, 'start': '2021-06-19 16:36:23.020569', 'end': '2021-06-19 16:36:23.040962', 'delta': '0:00:00.020393', 'changed': True, 'invocation': {'module_args': {'_raw_params': 'openssl passwd -6 -salt $(openssl rand -base64 48) temporal123', '_uses_shell': True, 'warn': True, 'stdin_add_newline': True, 'strip_empty_ends': True, 'argv': None, 'chdir': None, 'executable': None, 'creates': None, 'removes': None, 'stdin': None}}, 'stdout_lines': ['$6$9uAMaGXrvLrvXKaB$rZ1UjoXRwK5zz/fH1U8XsacokIuOxYMGMWvGGjwbFBE3pccXSHA8ZdVAp49jlmq5Z6QG5T2rYxb3G8/cttIdk1'], 'stderr_lines': [], 'failed': False, 'item': {'key': 'operator', 'value': {'password': 'temporal123', 'home': '/home/operator', 'gecos': 'usuario para tareas de operacion', 'shell': '/bin/bash', 'generate_ssh_keys': 'yes', 'ssh_key_size': 3072}}, 'ansible_loop_var': 'item'})
ok: [ansibleclient.jadbp.lab] => (item={'cmd': 'openssl passwd -6 -salt $(openssl rand -base64 48) 12345', 'stdout': '$6$3JRFaMShS0Z3Uxas$CHZ7tJf83HzEYql7BZJRCfqjy6ht7jH9IE9rXjat7if1S2sPbBT9/mqV.6xXkdQ5BWRF89kqKVJNtumqn2Niu0', 'stderr': '', 'rc': 0, 'start': '2021-06-19 16:36:23.901475', 'end': '2021-06-19 16:36:23.922370', 'delta': '0:00:00.020895', 'changed': True, 'invocation': {'module_args': {'_raw_params': 'openssl passwd -6 -salt $(openssl rand -base64 48) 12345', '_uses_shell': True, 'warn': True, 'stdin_add_newline': True, 'strip_empty_ends': True, 'argv': None, 'chdir': None, 'executable': None, 'creates': None, 'removes': None, 'stdin': None}}, 'stdout_lines': ['$6$3JRFaMShS0Z3Uxas$CHZ7tJf83HzEYql7BZJRCfqjy6ht7jH9IE9rXjat7if1S2sPbBT9/mqV.6xXkdQ5BWRF89kqKVJNtumqn2Niu0'], 'stderr_lines': [], 'failed': False, 'item': {'key': 'security', 'value': {'password': '12345', 'home': '/home/security', 'gecos': 'usuario de seguridad', 'shell': '/bin/bash', 'generate_ssh_keys': 'yes', 'ssh_key_size': 4096}}, 'ansible_loop_var': 'item'})
ok: [ansibleclient.jadbp.lab] => (item={'cmd': 'openssl passwd -6 -salt $(openssl rand -base64 48) password', 'stdout': '$6$KDLt/J+3OGjy6yoy$6gooIcaHfcZCDB7w3PI4JZXU/GWroGHhEjM651bsqHr18x0C2umjtvJ6PPIQF/29CMhCl/cPyXt4tG22exPoO0', 'stderr': '', 'rc': 0, 'start': '2021-06-19 16:36:24.643709', 'end': '2021-06-19 16:36:24.663829', 'delta': '0:00:00.020120', 'changed': True, 'invocation': {'module_args': {'_raw_params': 'openssl passwd -6 -salt $(openssl rand -base64 48) password', '_uses_shell': True, 'warn': True, 'stdin_add_newline': True, 'strip_empty_ends': True, 'argv': None, 'chdir': None, 'executable': None, 'creates': None, 'removes': None, 'stdin': None}}, 'stdout_lines': ['$6$KDLt/J+3OGjy6yoy$6gooIcaHfcZCDB7w3PI4JZXU/GWroGHhEjM651bsqHr18x0C2umjtvJ6PPIQF/29CMhCl/cPyXt4tG22exPoO0'], 'stderr_lines': [], 'failed': False, 'item': {'key': 'backup', 'value': {'password': 'password', 'home': '/var/lib/backup', 'gecos': 'usuario para ejecutar el agente de backup', 'shell': '/sbin/nologin', 'generate_ssh_keys': 'no', 'ssh_key_size': 0}}, 'ansible_loop_var': 'item'})
ok: [ansibleclient.jadbp.lab] => (item={'cmd': 'openssl passwd -6 -salt $(openssl rand -base64 48) enunlugardelamancha', 'stdout': '$6$VVimAYh5l7fhB6TT$nScabjl9ygRlapeWDR9eQ2z7kV5MabZw1rDDlSZEpHEwEnZsiHFKhNljL41uIaDZ.D32S7kpww3igD01NX5cQ0', 'stderr': '', 'rc': 0, 'start': '2021-06-19 16:36:25.500658', 'end': '2021-06-19 16:36:25.523812', 'delta': '0:00:00.023154', 'changed': True, 'invocation': {'module_args': {'_raw_params': 'openssl passwd -6 -salt $(openssl rand -base64 48) enunlugardelamancha', '_uses_shell': True, 'warn': True, 'stdin_add_newline': True, 'strip_empty_ends': True, 'argv': None, 'chdir': None, 'executable': None, 'creates': None, 'removes': None, 'stdin': None}}, 'stdout_lines': ['$6$VVimAYh5l7fhB6TT$nScabjl9ygRlapeWDR9eQ2z7kV5MabZw1rDDlSZEpHEwEnZsiHFKhNljL41uIaDZ.D32S7kpww3igD01NX5cQ0'], 'stderr_lines': [], 'failed': False, 'item': {'key': 'monitoring', 'value': {'password': 'enunlugardelamancha', 'home': '/var/lib/monitoring', 'gecos': 'usuario para ejecutar el agente de monitorizacion', 'shell': '/sbin/nologin', 'generate_ssh_keys': 'no', 'ssh_key_size': 0}}, 'ansible_loop_var': 'item'})

TASK [passwd : change shadow password hash] **************************************************************************************************************************************************************************************************
changed: [ansibleclient.jadbp.lab] => (item={'key': 'operator', 'value': '$6$9uAMaGXrvLrvXKaB$rZ1UjoXRwK5zz/fH1U8XsacokIuOxYMGMWvGGjwbFBE3pccXSHA8ZdVAp49jlmq5Z6QG5T2rYxb3G8/cttIdk1'})
changed: [ansibleclient.jadbp.lab] => (item={'key': 'security', 'value': '$6$3JRFaMShS0Z3Uxas$CHZ7tJf83HzEYql7BZJRCfqjy6ht7jH9IE9rXjat7if1S2sPbBT9/mqV.6xXkdQ5BWRF89kqKVJNtumqn2Niu0'})
changed: [ansibleclient.jadbp.lab] => (item={'key': 'backup', 'value': '$6$KDLt/J+3OGjy6yoy$6gooIcaHfcZCDB7w3PI4JZXU/GWroGHhEjM651bsqHr18x0C2umjtvJ6PPIQF/29CMhCl/cPyXt4tG22exPoO0'})
changed: [ansibleclient.jadbp.lab] => (item={'key': 'monitoring', 'value': '$6$VVimAYh5l7fhB6TT$nScabjl9ygRlapeWDR9eQ2z7kV5MabZw1rDDlSZEpHEwEnZsiHFKhNljL41uIaDZ.D32S7kpww3igD01NX5cQ0'})

PLAY RECAP ***********************************************************************************************************************************************************************************************************************************
ansibleclient.jadbp.lab    : ok=6    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

[jadebustos@ansiblectrl labs-ansible]$ 
```
