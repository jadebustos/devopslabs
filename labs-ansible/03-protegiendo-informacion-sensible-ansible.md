# Protegiendo información sensible en ansible

Cuando escribimos playbooks muchas veces es necesario gestionar información confidencial, como contraseñas, claves privadas de SSH o TLS/SSL.

Estos datos no es buena idea el incluirlos en el código ya que al estar disponible en un repositorio de código es probable que usuarios que no deban tener acceso a esos datos puedan accederlos.

Por ese motivo en ansible se utilizan **vaults** para almacenar está información.

Con **ansible vault** podemos encriptar variables o ficheros almacenando las contraseñas en ficheros que no se distruiran con los playbooks.

Esto soluciona un problema pero introduce otro. ¿Como gestionamos/distribuimos el fichero de contraseñas de forma segura?

Ansible permite el uso de herramientas de terceras partes para almacenar las contraseñas, como por ejemplo:

+ [Cyberark](https://www.cyberark.com/resources/blog/securing-ansible-automation-environments-with-cyberark), [cyberark_authentication](https://docs.ansible.com/ansible/2.9/modules/cyberark_authentication_module.html).
+ [Hasicorp](https://www.vaultproject.io/), [hashi_vault](https://docs.ansible.com/ansible/2.9/plugins/lookup/hashi_vault.html).

## Encriptando variables

Cuando necesitemos incluir un dato confidencial en una variable necesitaremos encryptar su valor y para ello necesitaremos suministrar una contraseña. Eso lo podemos hacer de dos formas. La primera es facilitar la contraseña por teclado:

```console
[jadebustos@archimedes ansible]$ ansible-vault encrypt_string --ask-vault-pass '12345' --name 'password'
New Vault password: 
Confirm New Vault password: 
password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          65653662626432653136333565336437656135633238363139373131336465616537333336363632
          3462333662356334653736326136323334643730643933300a376466303366393363323334666237
          35303864623230633330333239306439316632303665373834373734353062636664396237643862
          6134353938633038380a326562626638393763363861656564633563353266636262613162663765
          3439
Encryption successful
[jadebustos@archimedes ansible]$ 
```

Creamos un fichero llamado **secret.yaml**:

```yaml
password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          65653662626432653136333565336437656135633238363139373131336465616537333336363632
          3462333662356334653736326136323334643730643933300a376466303366393363323334666237
          35303864623230633330333239306439316632303665373834373734353062636664396237643862
          6134353938633038380a326562626638393763363861656564633563353266636262613162663765
          3439
```

Para recuperarlo:

```console
[jadebustos@archimedes ansible]$ ansible localhost -m debug -a var="password" -e "@secret.yaml" --ask-vault-pass
Vault password: 
localhost | SUCCESS => {
    "password": "12345"
}
[jadebustos@archimedes ansible]$
```

También podemos guardar la contraseña en un fichero:

```console
[jadebustos@archimedes ansible]$ echo "hola" > passwd-file
[jadebustos@archimedes ansible]$ ansible-vault encrypt_string --vault-password-file passwd-file '12345' --name 'password'
password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          65383334353136646432653136303565656237636230653537663833646462386163393237623638
          6437666230373237346634376134656131323038663335610a636134333864363234303737316439
          38363039666461343837643664346465636262353762666631383039633639613034623465636663
          3863383436316437330a383231633061646564366164646666313961376635636638306432353533
          6437
Encryption successful
[jadebustos@archimedes ansible]$ 
```

Hemos encriptado el valor **12345** con la clave **hola** como valor de la variable **password**. Creamos el fichero **secret.yaml**:

 ```yaml
 password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          65383334353136646432653136303565656237636230653537663833646462386163393237623638
          6437666230373237346634376134656131323038663335610a636134333864363234303737316439
          38363039666461343837643664346465636262353762666631383039633639613034623465636663
          3863383436316437330a383231633061646564366164646666313961376635636638306432353533
          6437
 ```

 Para acceder al valor de la variable leyendo la clave de encriptación de un fichero:

 ```console
 [jadebustos@archimedes ansible]$ ansible localhost -m debug -a var="password" -e "@secret.yaml" --vault-password-file passwd-file
localhost | SUCCESS => {
    "password": "12345"
}
[jadebustos@archimedes ansible]$
 ```

Podemos encriptar varias variables con diferentes contraseñas y añadir ids para distinguirlas. Creamos un fichero de claves:

 ```console
[jadebustos@archimedes ansible]$ echo "hola" > jose-key
[jadebustos@archimedes ansible]$ echo "mundo" > manuel-key
[jadebustos@archimedes ansible]$ echo "nuevo" > jesus-key
 ```

Utilizando estas claves encriptamos la contraseña de cada uno de estos usuarios:

```console
[jadebustos@archimedes ansible]$ ansible-vault encrypt_string --vault-id jose@jose-key '12345' --name 'password' > secret-jose.yaml
[jadebustos@archimedes ansible]$ cat secret-jose.yaml 
password: !vault |
          $ANSIBLE_VAULT;1.2;AES256;jose
          63306438393932313433353264303561656362353031306464363630313832346439343035386633
          6537373034366231353865383766303032306135343066650a633435663266343238613036343336
          39393230396638653432333866313733626130373331393237623861353464393165353231643263
          3038303436336664330a636135333630333432306333343463333436316534363063653735356162
          3538
[jadebustos@archimedes ansible]$ ansible-vault encrypt_string --vault-id manuel@manuel-key '67890' --name 'password' > secret-manuel.yaml
[jadebustos@archimedes ansible]$ ansible-vault encrypt_string --vault-id jesus@jesus-key 'abcde' --name 'password' > secret-jesus.yaml
[jadebustos@archimedes ansible]$
```

Para recuperar las contraseñas:

```console
[jadebustos@archimedes ansible]$ ansible localhost -m debug -a var="password" -e "@secret-jose.yaml" --vault-id jose@jose-key
localhost | SUCCESS => {
    "password": "12345"
}
$ ansible localhost -m debug -a var="password" -e "@secret-manuel.yaml" --vault-id manuel@manuel-key
localhost | SUCCESS => {
    "password": "67890"
}
$ ansible localhost -m debug -a var="password" -e "@secret-jesus.yaml" --vault-id jesus@jesus-key
localhost | SUCCESS => {
    "password": "abcde"
}
[jadebustos@archimedes ansible]$ 
```

## Encriptando variables (Ejemplo)

El playbook [clonar-git.yaml](clonar-git.yaml) se encarga de clonar un repositorio privado para lo cual hace falta la clave del usuario.

Para clonar el repositorio [https://github.com/jadebustos/devops](https://github.com/jadebustos/devops) la url que se utilizará:

```
https://jadebustos@PASSWDgithub.com/jadebustos/devops
```

La tarea de ansible sería:

```yaml
- name: clona repositorio git privado
  git:
    repo: https://jadebustos:PASSWD{@github.com/jadebustos/devops.git
    dest: "{{ target_dir }}"
```

Por lo tanto la contraseña del usuario sería accesible para todas las personas con acceso al repositorio.

Para ello encriptaremos la variable tal y como hemos visto reescribiendo la tarea:

```yaml
- name: clona repositorio git privado
  git:
    repo: "https://{{ user }}:{{ password }}@github.com/{{ user }}/{{ private_repo_name }}.git
    dest: "{{ target_dir }}"
```

Donde hemos definido las variables en el fichero [clonerepo.yaml](group_vars/clonerepo.yaml).

La contraseña de acceso la encriptamos en la variable **password** y almacenada en el fichero **group_vars/vault-file.yaml**:

```console
[jadebustos@archimedes ansible]$ ansible-vault encrypt_string --vault-password-file git-password 'MICONTRASEÑA' --name password > group_vars/vault-file.yaml
```

En el fichero **git-password** almacenamos la clave con la que encriptamos la contraseña del usuario.

```console
[jadebustos@archimedes ansible]$ ansible-playbook -i hosts -l laptop clonar-git.yaml --vault-password-file git-password

PLAY [clonar repositorio privado] ************************************************************************************************************************************************************************************************************

TASK [clonerepo : include_tasks] *************************************************************************************************************************************************************************************************************
included: /home/jadebustos/src/mygithub/devops/ansible/roles/clonerepo/tasks/01-clone.yaml for localhost

TASK [clonerepo : clona repositorio git privado] *********************************************************************************************************************************************************************************************
changed: [localhost]

PLAY RECAP ***********************************************************************************************************************************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

[jadebustos@archimedes ansible]$ ls -lh /tmp/git/
total 108K
-rw-rw-r--. 1 jadebustos jadebustos 8.1K Jan 19 23:41 01-terraform-kvm-provider.md
-rw-rw-r--. 1 jadebustos jadebustos 6.9K Jan 19 23:41 02-instalacion-docker.md
-rw-rw-r--. 1 jadebustos jadebustos  27K Jan 19 23:41 03-creando-containers-docker.md
-rw-rw-r--. 1 jadebustos jadebustos 1.2K Jan 19 23:41 04-instalacion-podman.md
-rw-rw-r--. 1 jadebustos jadebustos 9.8K Jan 19 23:41 05-creando-containers-podman.md
drwxrwxr-x. 4 jadebustos jadebustos  140 Jan 19 23:41 ansible
-rw-rw-r--. 1 jadebustos jadebustos  932 Jan 19 23:41 cloud-init.md
drwxrwxr-x. 2 jadebustos jadebustos   60 Jan 19 23:41 imgs
-rw-rw-r--. 1 jadebustos jadebustos  35K Jan 19 23:41 LICENSE
-rw-rw-r--. 1 jadebustos jadebustos    8 Jan 19 23:41 README.md
drwxrwxr-x. 3 jadebustos jadebustos   60 Jan 19 23:41 terraform
[jadebustos@archimedes ansible]$
```

En este ejemplo tenemos la clave de encriptado en el fichero **git-password**:

```console
[jadebustos@archimedes ansible]$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   hosts

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	clonar-git.yaml
	git-password
	group_vars/clonerepo.yaml
	group_vars/vault-file.yaml
	roles/clonerepo/

no changes added to commit (use "git add" and/or "git commit -a")
[jadebustos@archimedes ansible]$
```

Como podemos ver hay varios ficheros pendientes de subir al repositorio. Con lo cual tendremos que tener cuidado de no hacer commit del fichero.

Para evitar errores podemos crear un fichero **.gitignore** para ignorar el fichero de claves:

```console
[jadebustos@archimedes ansible]$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   hosts

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	.gitignore
	clonar-git.yaml
	group_vars/clonerepo.yaml
	group_vars/vault-file.yaml
	roles/clonerepo/

no changes added to commit (use "git add" and/or "git commit -a")
[jadebustos@archimedes ansible]$
```

De esta forma nos aseguramos de no subir el fichero con la clave al repositorio.

Otra forma es guardar ese fichero fuera del directorio donde se encuentra el repositorio.

La forma recomendada es utilizar vaults como [Cyberark](https://www.cyberark.com/resources/blog/securing-ansible-automation-environments-with-cyberark) o [Hasicorp](https://www.vaultproject.io/).

## Encriptando ficheros

Puede ser necesario encriptar ficheros enteros, por ejemplo ficheros con claves o tokens:

```console
[jadebustos@archimedes vault]$ cat secret.yaml
secret:
  api_token: "32fcdcf7-e364-47e4-81ed-10265a1a3ef3"
  licence_key: "c8695835-dd11-4886-a2a4-ab88146e17c3"
[jadebustos@archimedes vault]$ ansible-vault encrypt secret.yaml 
New Vault password: 
Confirm New Vault password: 
Encryption successful
[jadebustos@archimedes vault]$ cat secret.yaml
$ANSIBLE_VAULT;1.1;AES256
34613939653131656434663336613138386639383864623832303163376235376637633065616134
3066633830326536363564353464663139346330363535350a646236306363366336366565306265
33373836326630653937643762333861613230386363333934613062613962346163313861303462
6666636235363736300a636231613030373539373261346462633764383437353862646561613764
37313232303863326464643532303736636639656333323534343139616539643966646135363966
38376362343137303961373938366265636265393430373835616435386532356631363861356138
36323032646266643439333734636637353433366330336437653137393066653836383439313836
38323237313164623830343530323464663131623235383933636534313033313131363430336662
61393332343966653866336436303363636264373539653632383662306338633161656632383936
3331666664373865313465623064636137626637393965343932
[jadebustos@archimedes vault]$
```

Podemos modificar los secrets utilizando:

```console
[jadebustos@archimedes vault]$ ansible-vault edit secret.yaml 
Vault password: 
```

Lo cual abrirá el secreto desencriptado en el editor por defecto para que lo modifiquemos.

Y también podemos consultarlo:

```console
[jadebustos@archimedes vault]$ ansible-vault view secret.yaml --ask-vault-pass
Vault password: 
secret:
  api_token: "32fcdcf7-e364-47e4-81ed-10265a1a3ef3"
  licence_key: "c8695835-dd11-4886-a2a4-ab88146e17c3"
[jadebustos@archimedes vault]$
```

## Encriptando ficheros (Ejemplo)

Vamos a desplegar una instancia en AWS encriptando el fichero de credenciales. Para ello creamos el fichero de credenciales y lo encriptamos utilizando la clave que hay en el fichero **password**:

```console
[jadebustos@archimedes ansible]$ cat defaults/secret.yaml                                                                            
aws_access_key: 'f8eb724a-74b9-4a03-a009-6892e16ad9e3'

aws_secret_key: '131ebc99-5e66-43d9-8bdf-c07c274384c0'

[jadebustos@archimedes ansible]$ ansible-vault encrypt defaults/secret.yaml --vault-password-file password 
Encryption successful
[jadebustos@archimedes ansible]$ cat defaults/secret.yaml  
$ANSIBLE_VAULT;1.1;AES256
36326465653965643261663335626465383539393865316636313134356430663032376532373835
6466643263636138353364313763373430386439373739370a613964313833383638346532666634
65363532353961313435396666623235326135643764656231343739626535303363656232353330
6438396536356533370a303164643037653431393465663835343663333165313339663338313130
32393639633062353839303166323630333236636238663935336238303265356437633032336431
35343335316537303461313833633661376463316665363934643466306336663337656466303836
33643663663831303835313538306132356536376634396638333739336364626534616661633865
66303633343938323038383435613766323634303433313936666633316530336531356637666638
33643062396231346639323663653766323636626230643864666465393265653634
[jadebustos@archimedes ansible]$
```

El playbook [deploy-amazon-instance.yaml][deploy-amazon-instance.yaml] es un ejemplo de como se utilizaría la encriptación de un fichero para proteger las credenciales:

```console
[jadebustos@archimedes ansible]$ ansible-playbook -i hosts deploy-amazon-instance.yaml --vault-password-file password
```

## Seguridad

La protección que ofrece ansible vault se limita a cuando el dato se encuentra encriptado. Una vez que se desencripta los módulos y plugins tienen que utilizarlo de forma segura.

```console
[jadebustos@archimedes ansible]$ cat security.yaml 
---

- name: ejemplo seguridad
  hosts: all
  gather_facts: false
  vars_files:
    - secret-jose.yaml
  tasks:
    - name: uptime
      shell: "/usr/bin/uptime --value={{ password }}"
[jadebustos@archimedes ansible]$ ansible-playbook -i hosts security.yaml --vault-password-file jose-key 

PLAY [ejemplo seguridad] *********************************************************************************************************************************************************************************************************************

TASK [uptime] *********************************************************************************************************************************************************************************************************************************
fatal: [localhost]: FAILED! => {"changed": true, "cmd": "/usr/bin/uptime --value=12345", "delta": "0:00:00.002494", "end": "2021-01-19 23:05:16.777776", "msg": "non-zero return code", "rc": 1, "start": "2021-01-19 23:05:16.775282", "stderr": "/usr/bin/uptime: unrecognized option '--value=12345'\n\nUsage:\n uptime [options]\n\nOptions:\n -p, --pretty   show uptime in pretty format\n -h, --help     display this help and exit\n -s, --since    system up since\n -V, --version  output version information and exit\n\nFor more details see uptime(1).", "stderr_lines": ["/usr/bin/uptime: unrecognized option '--value=12345'", "", "Usage:", " uptime [options]", "", "Options:", " -p, --pretty   show uptime in pretty format", " -h, --help     display this help and exit", " -s, --since    system up since", " -V, --version  output version information and exit", "", "For more details see uptime(1)."], "stdout": "", "stdout_lines": []}

PLAY RECAP ***********************************************************************************************************************************************************************************************************************************
localhost                  : ok=1    changed=0    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0   

[jadebustos@archimedes ansible]$ 
```

Podemos ver en la salida del comando el secret:

```console
fatal: [localhost]: FAILED! => {"changed": true, "cmd": "/usr/bin/uptime --value=12345"
```

Podemos utilizar la directiva **no_log** para evitar esto:

```console
[jadebustos@archimedes ansible]$ cat security.yaml 
---

- name: ejemplo seguridad
  hosts: all
  gather_facts: false
  vars_files:
    - secret-jose.yaml
  tasks:
    - name: uptime
      shell: "/usr/bin/uptime --value={{ password }}"
      no_log: True
[jadebustos@archimedes ansible]$ ansible-playbook -i hosts security.yaml --vault-password-file jose-key 

PLAY [ejemplo seguridad] *********************************************************************************************************************************************************************************************************************

TASK [uptime] *********************************************************************************************************************************************************************************************************************************
fatal: [localhost]: FAILED! => {"censored": "the output has been hidden due to the fact that 'no_log: true' was specified for this result", "changed": true}

PLAY RECAP ***********************************************************************************************************************************************************************************************************************************
localhost                  : ok=0    changed=0    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0   
[jadebustos@archimedes ansible]$
```

## Recursos

+ [Using Hasicorp Vault to Secure Ansible Secrets](https://www.youtube.com/watch?v=_z0cbNP0i2g)
+ [CyberArk-Ansible end to end demo - 3: Securing newly created accounts](https://www.youtube.com/watch?v=qgyi-T0Ab3U)