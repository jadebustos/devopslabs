# Roles en ansible

Los [roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) en ansible es una forma de "empaquetar" código para poder reutilizarlo de forma fácil y sencilla.

Para la reutilización del código es muy importante el no hardcodear información en el playbook. Es decir toda aquella información susceptible de depender del entorno donde se vaya a ejecutar deberemos configurarla via variables. Separando código de datos.

De esta forma podremos reutilizar los roles de forma sencilla modificando únicamente el fichero de variables para proporcionar la información del entorno sobre el que vamos a realizar la ejecución.

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

Los roles se incluiran dentro de un directorio llamado **roles**. Dentro de este directorio se creará un directorio con el nombre del role, y dentro de el estarán los directorios que definen la estructura del role.

Los principales directorios, más utilizados, son los siguientes:

+ **tasks**, contendrá las tareas a ejecutar por el role. Deberán ir en un fichero llamado **main.yaml**.
+ **files**, contendrá ficheros que se quieran copiar a los clientes con el role de ansible.
+ **templates**, contendrá templates de ficheros que se quieran copiar a los clientes con el role de ansible.

## Creación de un playbook usando roles

Vamos a crear un playbook usando roles.

El playbook que vamos a crear se encargará de crear varios usuarios y asignarles un password. Para ello crearemos dos roles, uno para crear los usuarios y otro para asignarles el password a los usuarios.

> ![NOTE](../imgs/note-icon.png) Sería posible incluir todas las tareas en un único role. Se han utilizado dos roles para ilustrar como invocar varios roles desde un playbook.

Lo primero que vamos a hacer es crear un fichero con los datos de los usuarios. Aunque hemos visto que existe un directorio **vars** dentro de la estructura del role que tiene el propósito de almacenar las variables del role, en este caso crearemos un fichero [group_vars/users.yaml](group_vars/users.yaml):

```yaml
---

# diccionario con la información de usuarios a crear
users:
  operator:
    password: 'temporal123'
    home: '/home/operator'
    gecos: 'usuario para tareas de operacion'
    shell: '/bin/bash'
    generate_ssh_keys: 'yes'
    ssh_key_size: 3072
  security:
    password: '12345'
    home: '/home/security'
    gecos: 'usuario de seguridad'
    shell: '/bin/bash'
    generate_ssh_keys: 'yes'
    ssh_key_size: 4096
  backup:
    password: 'password'
    home: '/var/lib/backup'
    gecos: 'usuario para ejecutar el agente de backup'
    shell: '/sbin/nologin'
    generate_ssh_keys: 'no'
    ssh_key_size: 0
  monitoring:
    password: 'enunlugardelamancha'
    home: '/var/lib/monitoring'
    gecos: 'usuario para ejecutar el agente de monitorizacion'
    shell: '/sbin/nologin'
    generate_ssh_keys: 'no'
    ssh_key_size: 0
```

> ![IMPORTANT](../imgs/important-icon.png) En este caso la contraseña va en claro. Esto no es una buena práctica.

La estructura anterior crea un diccionario, **users**, cuyas claves son los nombres de los usuarios (**operator**, **security**, **backup** y **monitoring**) y a cada usuario se le definen sus propiedades (**password**, **home**, **gecos**, **shell**, **generate_ssh_keys** y **ssh_key_size**).

A cotinuación crearemos un role llamado **users** dentro de [roles/users](roles/users):

```console
[jadebustos@ansiblectrl labs-ansible]$ tree roles/users/
roles/users/
└── tasks
    ├── 01-create.yaml
    └── main.yaml

1 directory, 2 files
[jadebustos@ansiblectrl labs-ansible]$ 
```

El fichero [roles/users/tasks/main.yaml](roles/users/tasks/main.yaml) incluye todas las tareas a realizar por el role:

```yaml
---

- include_tasks: 01-create.yaml
```

En este caso las tareas las hemos incluido en un fichero [roles/users/tasks/01-create.yaml](roles/users/tasks/01-create.yaml):

```yaml
---

- name: create users
  user:
    name: "{{ item.key }}"
    comment: "{{ item.value.gecos }}"
    home: "{{ item.value.home }}"
    shell: "{{ item.value.shell }}"
    generate_ssh_key: "{{ item.value.generate_ssh_keys }}"
    ssh_key_bits: "{{ item.value.ssh_key_size }}"
  become: yes
  with_dict:
    - "{{ users }}"
```

Se iterará sobre el diccionario **users**, sobre sus claves (**operator**, **security**, **backup** y **monitoring**) donde:

+ **user** es el módulo de ansible que se utilizará. El módulo [user](https://docs.ansible.com/ansible/2.9/modules/user_module.html) creará usuarios en el sistema operativo.
+ **item.key** será la clave sobre la que estamos iterando, el nombre del usuario.
+ **item.value.gecos** será el valor del campo **gecos** de la clave sobre la que estemos iterando.
+ **item.value.home** será el valor del campo **home** de la clave sobre la que estemos iterando.
+ **item.value.shell** será el valor del campo **shell** de la clave sobre la que estemos iterando.
+ **item.value.generate_ssh_keys** será el valor del campo **generate_ssh_keys** de la clave sobre la que estemos iterando.
+ **item.value.ssh_key_bits** será el valor del campo **ssh_key_bits** de la clave sobre la que estemos iterando.
+ **become: yes** indica que la tarea se tiene que ejecutar como usuario **root**.
+ **with_dict** indica que se iterará sobre un diccionario.

Este role creará los usuarios, pero no les asigna contraseñas. Aunque es posible asignar la contraseña en el código anterior vamos a crear un role a parte para realizar esta tarea para poder reutilizarlo para cambiar las contraseñas de los usuarios cuando sea necesario.

El role para cambiar las contraseñas a los usuarios:

```console
[jadebustos@ansiblectrl labs-ansible]$ tree roles/passwd/
roles/passwd/
└── tasks
    ├── 01-password.yaml
    └── main.yaml

1 directory, 2 files
[jadebustos@ansiblectrl labs-ansible]$
```
El fichero [roles/passwd/tasks/main.yaml](roles/passwd/tasks/main.yaml) incluye todas las tareas a realizar por el role:

```yaml
---

- include_tasks: 01-password.yaml
```

En este caso las tareas las hemos incluido en un fichero [roles/users/tasks/01-password.yaml](roles/users/tasks/01-password.yaml):

```yaml
---

# creamos el hash de las passwords de los usuarios y lo almacenamos en una variable
- name: generate sha512 password hashes
  shell: "openssl passwd -6 -salt $(openssl rand -base64 48) {{ item.value.password }}"
  register: sha512
  with_dict:
    - "{{ users }}"

#- name: display sha512
#  debug: var=sha512

#- name: muestra los contenidos de sha512.results
#  debug: var=item.stdout
#  with_items:
#    - "{{ sha512.results }}"

# crea un diccionario donde la clave es el nombre del usuario y el password el hash de su contraseña
# para ver la estructura de sha512 y los campos que tiene puedes descomentar las tarea anteriores que
# imprimiran el contenido de la variable sha512 que nos valdrá para conocer su estructura y poder
# crear el diccionario con los hashes de las contraseñas
- name: create a dictionary with password hashes
  set_fact:
    passwdhashes: "{{ passwdhashes|default({}) | combine( {item.item.key: item.stdout} ) }}"
  with_items: "{{ sha512.results }}"

# descomentando esta tarea podemos ver la estructura creada
- name: display passwordhashes
  debug: var=passwdhashes

# cambiamos el password de los usuarios
- name: change shadow password hash
  user:
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