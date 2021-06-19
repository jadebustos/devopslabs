# Facts

Cuando ansible se conecta a una máquina puede recoger información de la máquina y almacenarla en variables para su porterior uso:

```console
[jadebustos@ansiblectrl labs-ansible]$ ansible -i hosts -l local -m setup all
localhost | SUCCESS => {
    "ansible_facts": {
        "ansible_all_ipv4_addresses": [
            "192.168.1.176"
        ],
        "ansible_all_ipv6_addresses": [
            "fe80::69e4:6df:909d:bde7"
        ],
        "ansible_apparmor": {
            "status": "disabled"
        },
        "ansible_architecture": "x86_64",
        "ansible_bios_date": "04/01/2014",
        "ansible_bios_version": "1.14.0-3.fc34",
        "ansible_cmdline": {
            "BOOT_IMAGE": "(hd0,msdos1)/vmlinuz-4.18.0-310.el8.x86_64",
            "crashkernel": "auto",
            "quiet": true,
            "rd.lvm.lv": "cs/swap",
            "resume": "/dev/mapper/cs-swap",
            "rhgb": true,
            "ro": true,
            "root": "/dev/mapper/cs-root"
        },
...
}
[jadebustos@ansiblectrl labs-ansible]$
```

Si queremos enviar los facts a un fichero podemos redirigir la salida estandar hacía el fichero:

```console
[jadebustos@ansiblectrl labs-ansible]$ ansible -i hosts -l local -m setup all > /tmp/local.json
[jadebustos@ansiblectrl labs-ansible]$ ls -lh /tmp/
total 28K
-rw-rw-r--. 1 jadebustos jadebustos 25K Jun 19 18:55 local.json
[jadebustos@ansiblectrl labs-ansible]$ 
```

También podemos indicar que se redirigan de forma automática a un directorio. Esto es útil cuando queremos recuperar los facts de varios sistemas:

```console
[jadebustos@ansiblectrl labs-ansible]$ ansible -i hosts -l localhost,ansibleclient.jadbp.lab -m setup all --tree /tmp/facts
localhost | SUCCESS => {
    "ansible_facts": {
        "ansible_all_ipv4_addresses": [
            "192.168.1.176"
        ],
        "ansible_all_ipv6_addresses": [
            "fe80::69e4:6df:909d:bde7"
        ],
        "ansible_apparmor": {
            "status": "disabled"
        },
...
[jadebustos@ansiblectrl labs-ansible]$ ls -lh /tmp/
total 28K
drwxrwxr-x. 2 jadebustos jadebustos  54 Jun 19 18:58 facts
-rw-rw-r--. 1 jadebustos jadebustos 25K Jun 19 18:55 local.json
[jadebustos@ansiblectrl labs-ansible]$ ls -lh /tmp/facts/
total 32K
-rw-rw-r--. 1 jadebustos jadebustos 16K Jun 19 18:58 ansibleclient.jadbp.lab
-rw-rw-r--. 1 jadebustos jadebustos 16K Jun 19 18:58 localhost
[jadebustos@ansiblectrl labs-ansible]$ 
```

Si editamos los ficheros generados veremos que son un único stream, es decir que es una única línea. Si queremos consultarlos podemos reescribirlos de una forma más legible:

```console
[jadebustos@ansiblectrl labs-ansible]$ cd /tmp/facts/
[jadebustos@ansiblectrl facts]$ for i in $(ls *)
> do
> python3 -m json.tool $i > "formatted-$i.json"
> done
[jadebustos@ansiblectrl facts]$ ls -lh
total 88K
-rw-rw-r--. 1 jadebustos jadebustos 16K Jun 19 18:58 ansibleclient.jadbp.lab
-rw-rw-r--. 1 jadebustos jadebustos 25K Jun 19 19:05 formatted-ansibleclient.jadbp.lab.json
-rw-rw-r--. 1 jadebustos jadebustos 25K Jun 19 19:05 formatted-localhost.json
-rw-rw-r--. 1 jadebustos jadebustos 16K Jun 19 18:58 localhost
[jadebustos@ansiblectrl facts]$ 
```

También podemos utilizar el comando **jq** sobre el fichero de facts para extraer información:

```console
[jadebustos@ansiblectrl facts]$ cat ansibleclient.jadbp.lab | jq '.ansible_facts.ansible_fqdn'
"ansibleclient.jadbp.lab"
[jadebustos@ansiblectrl facts]$ cat ansibleclient.jadbp.lab | jq '.ansible_facts.ansible_all_ipv4_addresses[0]'
"192.168.1.177"
[jadebustos@ansiblectrl facts]$ cat ansibleclient.jadbp.lab | jq '.ansible_facts.ansible_all_ipv4_addresses'
[
  "192.168.1.177"
]
[jadebustos@ansiblectrl facts]$ 
```

> ![INFORMATION](../imgs/information-icon.png): [Ansible Facts](https://docs.ansible.com/ansible/latest/user_guide/playbooks_vars_facts.html)

## Utilizando facts (Ejemplo)

El playbook [configurar-red.yaml](configurar-red.yaml) recrea un fichero de configuración de red en **/tmp/ifcfg-nombre_interface** utilizando la información contenida en los facts basandose en el template [network.j2](roles/networkconf/templates/network.j2). El fichero de configuración sigue el formato utilizado en Red Hat y derivados:

```console
[jadebustos@ansiblectrl labs-ansible]$ ansible-playbook -i hosts -l client configurar-red.yaml 

PLAY [configurar red (ejemplo utilizacion facts)] ********************************************************************************************************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************************************************************************************************************************************
ok: [ansibleclient.jadbp.lab]

TASK [networkconf : include_tasks] ***********************************************************************************************************************************************************************************************************
included: /home/jadebustos/devopslabs/labs-ansible/roles/networkconf/tasks/01-network.yaml for ansibleclient.jadbp.lab

TASK [networkconf : crear configuracion de red] **********************************************************************************************************************************************************************************************
changed: [ansibleclient.jadbp.lab]

PLAY RECAP ***********************************************************************************************************************************************************************************************************************************
ansibleclient.jadbp.lab    : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

[jadebustos@ansiblectrl labs-ansible]$
```
> ![INFORMATION](../imgs/information-icon.png) [Templates (Jinja2)](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html)

Si nos conectamos al equipo podemos comparar el fichero generado con la información de los facts y el fichero real de configuración:

```console
[ansible@ansibleclient ~]$ cat /tmp/ifcfg-enp1s0 
BOOTPROTO=none
DEFROUTE=yes
DEVICE=enp1s0
DNS1=192.168.1.200
GATEWAY=192.168.1.1
IPADDR=192.168.1.177
NETMASK=255.255.255.0
ONBOOT=yes
TYPE=Ethernet
USERCTL=no[ansible@ansibleclient ~]$ cat /etc/sysconfig/network-scripts/ifcfg-enp1s0 
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=enp1s0
UUID=7ff72f73-5b87-4685-8dd2-c92fed809bcb
DEVICE=enp1s0
ONBOOT=yes
IPADDR=192.168.1.177
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
DNS1=192.168.1.200
DOMAIN="jadbp.lab"
[ansible@ansibleclient ~]$ 
```

La recolección de facts lleva algo de tiempo, para la ejecución en un sistema es algo asumible. Sin embargo, cuando se ejecuta un playbook en varios equipos puede llevar mucho tiempo. Si no se necesita la información contenida en los facts se desactiva la recolección de información con **gather_facts: false**.

El playbook que hemos creado necesita el valor **gather_facts** a **true** ya que utiliza la información recolectada en los facts: 

```console
---

- name: configurar red (ejemplo utilizacion facts)
  hosts: all
  gather_facts: true
  roles:
    - networkconf
```

En los facts la información de red, menos los dns, se saca de la siguiente estructura:

```console
[jadebustos@ansiblectrl labs-ansible]$ cat /tmp/formatted-ansibleclient.jadbp.lab.json | jq '.ansible_facts.ansible_default_ipv4'
{
  "address": "192.168.1.177",
  "alias": "enp1s0",
  "broadcast": "192.168.1.255",
  "gateway": "192.168.1.1",
  "interface": "enp1s0",
  "macaddress": "52:54:00:d1:55:0f",
  "mtu": 1500,
  "netmask": "255.255.255.0",
  "network": "192.168.1.0",
  "type": "ether"
}
[jadebustos@ansiblectrl labs-ansible]$  
```

La información de dns se obtiene de la siguiente estructura:

```console
[jadebustos@ansiblectrl labs-ansible]$ cat /tmp/facts/formatted-ansibleclient.jadbp.lab.json | jq '.ansible_facts.ansible_dns.nameservers'
[
  "192.168.1.200"
]
[jadebustos@ansiblectrl labs-ansible]$ cat /tmp/facts/formatted-ansibleclient.jadbp.lab.json | jq '.ansible_facts.ansible_dns.nameservers[0]'
"192.168.1.200"
[jadebustos@ansiblectrl labs-ansible]$ 
```