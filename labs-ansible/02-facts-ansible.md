# Facts

Cuando ansible se conecta a una máquina puede recoger información de la máquina y almacenarla en variables para su porterior uso:

```console
[jadebustos@beast ansible]$ ansible -i hosts -l lab-docker.frontend.lab -m setup all
lab-docker.frontend.lab | SUCCESS => {
    "ansible_facts": {
...
        "ansible_default_ipv4": {
            "address": "192.168.23.100",
            "alias": "ens3",
            "broadcast": "192.168.23.255",
            "gateway": "192.168.23.1",
            "interface": "ens3",
            "macaddress": "52:54:00:c6:de:ec",
            "mtu": 1500,
            "netmask": "255.255.255.0",
            "network": "192.168.23.0",
            "type": "ether"
        },
...
}
[jadebustos@beast ansible]$
```

Si queremos enviar los facts a un fichero podemos redirigir la salida estandar hacía el fichero:

```console
[jadebustos@beast ansible]$ ansible -i hosts -l lab-docker.frontend.lab -m setup all > lab-docker_facts.json
[jadebustos@beast ansible]$
```

Tambien podemos indicar que se redirigan de forma automatica a un fichero. Esto es útil cuando queremos recuperar los facts de varios sistemas:

```console
[jadebustos@beast ansible]$ ansible -i hosts -l lab-docker.frontend.lab,lab-podman.frontend.lab -m setup all --tree facts
...
[jadebustos@beast ansible]$ ls -lh facts/
total 40K
-rw-r--r--. 1 jadebustos jadebustos 19K Jan 20 10:14 lab-docker.frontend.lab
-rw-r--r--. 1 jadebustos jadebustos 17K Jan 20 10:14 lab-podman.frontend.lab
[jadebustos@beast ansible]$ 
```

Si editamos los ficheros generados veremos que son un único stream, es decir que es una única línea. Si queremos consultarlos podemos reescribirlos de una forma más legible:

```console
[jadebustos@beast ansible]$  cd facts
[jadebustos@beast facts]$ for i in $(ls *)
> do
> python -m json.tool $i > "formatted-"$i".json"
> done
[jadebustos@beast facts]$ ls -lh
total 100K
-rw-r--r--. 1 jadebustos jadebustos 29K Jan 20 10:24 formatted-lab-docker.frontend.lab.json
-rw-r--r--. 1 jadebustos jadebustos 25K Jan 20 10:24 formatted-lab-podman.frontend.lab.json
-rw-r--r--. 1 jadebustos jadebustos 19K Jan 20 10:14 lab-docker.frontend.lab
-rw-r--r--. 1 jadebustos jadebustos 17K Jan 20 10:14 lab-podman.frontend.lab
[jadebustos@beast facts]$
```

También podemos utilizar el comando **jq** sobre el fichero de facts para extraer información:

```console
[jadebustos@beast facts]$ cat lab-docker.frontend.lab | jq '.ansible_facts.ansible_fqdn'
"lab-docker.frontend.lab"
[jadebustos@beast facts]$ cat lab-docker.frontend.lab | jq '.ansible_facts.ansible_all_ipv4_addresses'
[
  "172.17.0.1",
  "192.168.23.100"
]
[jadebustos@beast facts]$ cat lab-docker.frontend.lab | jq '.ansible_facts.ansible_all_ipv4_addresses[0]'
"172.17.0.1"
[jadebustos@beast facts]$  
```

> ![INFORMATION](../imgs/information-icon.png): [Ansible Facts](https://docs.ansible.com/ansible/latest/user_guide/playbooks_vars_facts.html)

## Utilizando facts (Ejemplo)

El playbook [configurar-red.yaml](configurar-red.yaml) recrea un fichero de configuración de red en **/tmp/ifcfg-nombre_interface** utilizando la información contenida en los facts basandose en el template [network.j2](roles/networkconf/templates/network.j2). El fichero de configuración sigue el formato utilizado en Red Hat y derivados:

```console
[jadebustos@beast ansible]$ ansible-playbook -i hosts -l docker configurar-red.yaml 

PLAY [configurar red (ejemplo utilizacion facts)] ************************************************************************************************************

TASK [Gathering Facts] ***************************************************************************************************************************************
ok: [lab-docker.frontend.lab]

TASK [networkconf : include_tasks] ***************************************************************************************************************************
included: /home/jadebustos/src/mygithub/devops/ansible/roles/networkconf/tasks/01-network.yaml for lab-docker.frontend.lab

TASK [networkconf : crear configuracion de red] **************************************************************************************************************
changed: [lab-docker.frontend.lab]

PLAY RECAP ***************************************************************************************************************************************************
lab-docker.frontend.lab    : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

[jadebustos@beast ansible]$
```

Si nos conectamos al equipo podemos comparar el fichero generado con la información de los facts y el fichero real de configuración:

```console
[terraform@lab-docker ~]$ cat /tmp/ifcfg-ens3 
BOOTPROTO=none
DEFROUTE=yes
DEVICE=ens3
DNS1=192.168.1.200
GATEWAY=192.168.23.1
IPADDR=192.168.23.100
NETMASK=255.255.255.0
ONBOOT=yes
TYPE=Ethernet
USERCTL=no[terraform@lab-docker ~]$ cat /etc/sysconfig/network-scripts/ifcfg-ens3 
# Created by cloud-init on instance boot automatically, do not edit.
#
BOOTPROTO=none
DEFROUTE=yes
DEVICE=ens3
DNS1=192.168.1.200
GATEWAY=192.168.23.1
IPADDR=192.168.23.100
NETMASK=255.255.255.0
ONBOOT=yes
TYPE=Ethernet
USERCTL=no
[terraform@lab-docker ~]$ 
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
[jadebustos@beast facts]$ cat formatted-lab-docker.frontend.lab.json | jq '.ansible_facts.ansible_default_ipv4' 
{
  "address": "192.168.23.100",
  "alias": "ens3",
  "broadcast": "192.168.23.255",
  "gateway": "192.168.23.1",
  "interface": "ens3",
  "macaddress": "52:54:00:c6:de:ec",
  "mtu": 1500,
  "netmask": "255.255.255.0",
  "network": "192.168.23.0",
  "type": "ether"
}
[jadebustos@beast facts]$ 
```

La información de dns se obtiene de la siguiente estructura:

```console
[jadebustos@beast facts]$ cat formatted-lab-docker.frontend.lab.json | jq '.ansible_facts.ansible_dns.nameservers' 
[
  "192.168.1.200"
]
[jadebustos@beast facts]$ cat formatted-lab-docker.frontend.lab.json | jq '.ansible_facts.ansible_dns.nameservers[0]' 
"192.168.1.200"
[jadebustos@beast facts]$ 
```