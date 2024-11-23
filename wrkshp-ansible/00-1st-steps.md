# First steps with Ansible

You will need two virtual machines (CentOS Stream 9):

+ **Ansible controller**, ansible engine will be deployed in this virtual machine.
+ **Ansible client**, you will use ansible to perform tasks on this virtual machine.

![NOTE](../imgs/note-icon.png) You will see that I will be writing all path for commands on playbooks. If the command is in the path it is not necessary. I wrote it in that way because it is a habit I have for a long time.

## Ansible deployment (CentOS Stream 9)

You will need to configure the [EPEL repository](https://dl.fedoraproject.org/pub/epel/) in the ansible controller to deploy the ansible engine:

```console
[root@controller ~]# dnf install https://dl.fedoraproject.org/pub/epel/epel{,-next}-release-latest-9.noarch.rpm
...
[root@controller ~]#
```

Once the repository has been configured we can install ansible and another utils:

```console
[root@controller ~]# dnf install ansible git tree jq tmux -y
...
[root@controller ~]#
```

Check that on the ansible cliente the **python36** package is installed:

```console
[root@ansibleclient ~]# dnf install python36 -y
...
[root@ansibleclient ~]#
```

## User creation

You will have to create one user in both servers:

In the both servers you will create the **ansible** user that will be the user we will use:

```console
[root@controller ~]# useradd -md /home/ansible ansible
[root@controller ~]# passwd ansible
Changing password for user ansible.
New password: 
BAD PASSWORD: The password is shorter than 8 characters
Retype new password: 
passwd: all authentication tokens updated successfully.
[root@controller ~]#
```

## Accessing nodes

To be able to access the nodes using ansible to run tasks you will need to configure SSH to authenticate with a public key. In the ansible controller you will create a public/private key for the **ansible** user.

To check if there already are public/private keys:

```console
[ansible@controller ~]$ ls -lh .ssh/*
-rw-------. 1 ansible ansible 1.9K Oct 14 20:00 .ssh/authorized_keys
-rw-------. 1 ansible ansible 1.7K Apr 15  2018 .ssh/id_rsa
-rw-r--r--. 1 ansible ansible  408 Jan 17 10:50 .ssh/id_rsa.pub
-rw-------. 1 ansible ansible 4.1K Jan 24 16:11 .ssh/known_hosts
[ansible@controller ~]$ 
```

If no keys are present you can create them:

```console
[ansible@controller ~]$ ssh-keygen -t rsa -b 4096
Generating public/private rsa key pair.
Enter file in which to save the key (/home/ansible/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in id_rsa
Your public key has been saved in id_rsa.pub
The key fingerprint is:
SHA256:d6ePc0yE/+ZhkgTgxPqpNn4iEV5vmbUnCUFt0YXPPUc ansible@controller.jadbp.lab
The key's randomart image is:
+---[RSA 4096]----+
|        o+..o o. |
|        oo.o o  E|
|        ..o. .o..|
|     . o . .o .+o|
|    . o S B ++. o|
|     o   O =.++  |
|      . o   += + |
|     . = .  .o= +|
|      +.+   .o.o.|
+----[SHA256]-----+
[ansible@controller ~]$
```

> ![IMPORTANT](../imgs/important-icon.png) Do not configure the private key with a password to allow ansible to connect to the nodes in an unattended way.

Once you have created the public/private keys in the ansible controller you will have to configure the ansible client server to accept that public key for the **ansible** user:

```console
[ansible@controller ~]$ ssh-copy-id -i .ssh/id_rsa.pub ansible@client
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: ".ssh/id_rsa.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
ansible@ansibleclient's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'ansible@ansibleclient'"
and check to make sure that only the key(s) you wanted were added.

[ansible@controller ~]$
```

Si despliegas las máquinas con terraform puedes utilizar **cloud-init** tanto para crear el usuario como para configurar la clave pública. En el código para desplegar las imágenes del laboratorio se pueden ver [ejemplos](../terraform/kvm/docker/user_config.cfg):

```yaml
#cloud-config
# configuracion de usuarios
#
users:
  - name: terraform
    gecos: terraform created user
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users
    ssh_import_id: None
    lock_passwd: true
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDbV8HMtQ1D6qfn+pRINxB4x4QROfbxiS4TQNcffzvaID0baF/t951aRuvHaexy2QKKVb9u3RJSZfEuUvDJaFq2Oo5An8wWZqKvj6AC+yrBpD8D1M7E9uUuwqOfDwEu7pw7Otz+bUWD/x1mbJ4UUQ2fe+kFuiI/siILm7mAAAj7JfKDF3T6OdmHjzVKXHlWiuaLEXns0IkiogBrC4v83ziMt8nq6P3jbPDqI87UOi1Dkvi5vdI7maSBfBwE2vWJGSsnOovDu1kYQJOFje/AQx1sByve/36prBsW1zehfXl/3/tPJtQc8j7h+IaUg8ZRvDazncgirKuneQ6rvyXcfzDX ansible@beast.melmac.univ

runcmd:
  - hostnamectl set-hostname lab-docker.frontend.lab
```

## Privilege escalation

To perform administrative tasks you will need to configure sudo to become root in the client server. So you will have to create the file **/etc/sudoers.d/ansible** with:

```bash
ansible ALL=(ALL) NOPASSWD:ALL
```

## Inventory

Ansible will deploy a general configuration in the file **/etc/ansible/ansible.cfg** but this file is not used in most of the cases due to it requires administrator privileges. Users should create their own configuration.

You will use an inventory file for the nodes you want to manage with the ansible engine:

```ini
[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_user=ansible

[podman]
lab-podman.melmac.univ

[containers]
lab-docker.melmac.univ
lab-podman.melmac.univ

[laptop]
localhost ansible_user=ansible
```

+ The square brackets are used to define group of servers.
+ **[all:vars]** is used to define variables for all the servers in the inventory, no matter the group they belong to. You can also define variable for a group, using **[podman:vars]** will define variable for the podman group.
+ **ansible_python_interpreter** is used to configure the python version to be used by ansible. This is not mandatory, but you can use different python versions to run ansible tasks.
+ **ansible_user** is used to define the user that will be used to connect to the ansible clients to run ansible tasks.
+ **localhost ansible_user=ansible** is used to configure the user that will be used to connect to an especific ansible client, in this case to **localhost**.

To run an ansible playbook using an inventory file named **hosts**:

```console
[ansible@controller ansible]$ ansible-playbook -i hosts playbook.yaml
```

To run an ansible playbook using an inventory file named **hosts** but only on the ansible clients on the **containers** group:

```console
[ansible@controller ansible]$ ansible-playbook -i hosts -l containers playbook.yaml
```

You will create an inventory for your enviroment:

```ini
[all:vars]
ansible_python_interpreter=/usr/bin/python3

[controller]
controller.melmac.univ ansible_connection=local

[client]
ansibleclient.melmac.univ ansible_user=ansible
```

The **ansible_connection** is used to configure the connection method. By default SSH will be used, in this case as **local** is defined that means that SSH will not be used. So we can run ansible tasks locally on **controller.melmac.univ** without using SSH.

> ![IMPORTANT](../imgs/important-icon.png) If you do not have DNS resolution for your enviroment servers you can use your **/etc/hosts** file.

## Ansible task execution

To verify that **ansible** has been properly configured in the controller:

```console
[ansible@controller ansible]$ cat hosts 
[all:vars]
ansible_python_interpreter=/usr/bin/python3

[controller]
controller.melmac.univ ansible_connection=local

[client]
ansibleclient.melmac.univ ansible_user=ansible
[ansible@controller ansible]$ ansible -i hosts -m ping all
controller.melmac.univ | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
ansibleclient.melmac.univ | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
[ansible@controller ansible]$ 
```

If you want to manage a node using ansible, python need to be installed on that node. If python is not installed:


```console
[ansible@controller ansible]$ ansible -i hosts -m ping all
ansibleclient.melmac.univ | FAILED! => {
    "changed": false,
    "module_stderr": "Shared connection to ansibleclient.melmac.univ closed.\r\n",
    "module_stdout": "/bin/sh: /usr/bin/python3: No such file or directory\r\n",
    "msg": "The module failed to execute correctly, you probably need to set the interpreter.\nSee stdout/stderr for the exact error",
    "rc": 127
}
controller.melmac.univ | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
[ansible@controller ansible]$
```

> ![TIP](../imgs/tip-icon.png) Ansible's ping module was used on all servers defined in the inventory file **hosts** to check if ansible is able to manage the nodes. The user used to connect is the one configured on the **ansible_user** variable.