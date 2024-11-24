# Using ansible facts

When ansible connects to a node it can recollect node's information, store it in variables which can be used for the tasks being executed in that node:

```console
[ansible@controller wrkshp-ansible]$ ansible -i hosts -l client -m setup all


[ansible@controller wrkshp-ansible]$
```

You can redirect the output to a file:

```console
[ansible@controller wrkshp-ansible]$ ansible -i hosts -l client -m setup all > /tmp/local.json
[ansible@controller wrkshp-ansible]$ ls -lh /tmp/



[ansible@controller wrkshp-ansible]$ 
```

You can also forward the output to a directory:

```console
[ansible@controller wrkshp-ansible]$ ansible -i hosts -l client -m setup all --tree /tmp/facts




[ansible@controller wrkshp-ansible]$ ls -lh /tmp/



[ansible@controller wrkshp-ansible]$ ls -lh /tmp/facts/




[ansible@controller wrkshp-ansible]$ 
```

The JSON facts file is an one-line file, so you can pretty print them:

```console
[ansible@controller wrkshp-ansible]$ cd /tmp/facts/
[ansible@controller facts]$ for i in $(ls *)
> do
> python3 -m json.tool $i > "formatted-$i.json"
> done
[ansible@controller facts]$ ls -lh




[ansible@controller facts]$ 
```

You can use the **jq** command to extract information from the JSON facts file:

```console
[ansible@controller facts]$ cat client.melmac.univ | jq '.ansible_facts.ansible_fqdn'
"client.melmac.univ"
[ansible@controller facts]$ cat client.melmac.univ | jq '.ansible_facts.ansible_all_ipv4_addresses[0]'
"192.168.122.231
[ansible@controller facts]$ cat client.melmac.univ | jq '.ansible_facts.ansible_all_ipv4_addresses'
[
  "192.168.122.231"
]
[ansible@controller facts]$ 
```

## How to use Ansible facts

Playbook [network-configuration.yaml](network-configuration.yaml) will create the network configuration file in **/tmp/ifcfg-interface_name** using information from the facts. This is a silly example but it illustrates how to use ansible facts and jinja2 templates. The playbook will use the jinja 2 template [network.j2](roles/networkconf/templates/network.j2).

```console
[ansible@controller wrkshp-ansible]$ ansible-playbook -i hosts -l client network-configuration.yaml 





[ansible@controller wrkshp-ansible]$
```

You can check the configuration file created by the playbook:

```console
[ansible@client ~]$ cat /tmp/ifcfg-enp1s0 



[ansible@client ~]$ 
```

Facts gathering takes some time. If you do not need the information from the facts you can disable facts gathering using **gather_facts: false**.

To gather facts you will need to use **gather_facts: true**: 

```console
---

- name: create network configuration file
  hosts: all
  gather_facts: true
  roles:
    - networkconf
```

Network configuration in the ansible facts is taken from the following estructure:

```console
[ansible@controller wrkshp-ansible]$ cat /tmp/formatted-client.melmac.univ.json | jq '.ansible_facts.ansible_default_ipv4'
{



[ansible@controller wrkshp-ansible]$  
```

DNS information is taken from:

```console
[ansible@controller wrkshp-ansible]$ cat /tmp/facts/formatted-client.melmac.univ.json | jq '.ansible_facts.ansible_dns.nameservers'





[ansible@controller wrkshp-ansible]$ cat /tmp/facts/formatted-client.melmac.univ.json | jq '.ansible_facts.ansible_dns.nameservers[0]'





[ansible@controller wrkshp-ansible]$ 
```

## Ansible facts practical use case

Una tarea habitual que se suele hacer en las tareas de administración es al de crear un sistema de fichero o bien ampliar uno existente.

Queramos crear un nuevo filesystem o ampliar uno ya existente (necesitando ampliar un Volume Group) lo que necesitamos es conocer el dispositivo físico sobre el que necesitemos actuar. Necesitaremos encontrar un dispositivo que este libre, en el sentido de que no tenga ninguna partición creada y pueda ser utilizado para crear un filesystem que ocupe todo el disco o bien utilizar todo el disco para ampliar un Volume Group.

Si recogemos los facts de un equipo tendremos acceso a información sobre los dispositivos presentes, y obtendremos una salida similar a esta para un disco con particiones (disco que no se podrá utilizar para ampliar un sistema de ficheros)

```yaml
"sda": {
    "holders": [],
    "host": "SATA controller: Marvell Technology Group Ltd. 88SE9230 PCIe 2.0 x2 4-port SATA 6 Gb/s RAID Controller (rev 11)",
    "links": {
      "ids": [
        "ata-MARVELL_Raid_VD_41d64e2a9e180001"
      ],
      "labels": [],
      "masters": [],
      "uuids": []
    },
    "model": "MARVELL Raid VD",
    "partitions": {
      "sda1": {
        "holders": [],
        "links": {
          "ids": [
            "ata-MARVELL_Raid_VD_41d64e2a9e180001-part1"
          ],
          "labels": [],
          "masters": [],
          "uuids": []
        },
        "sectors": "2048",
        "sectorsize": 512,
        "size": "1.00 MB",
        "start": "2048",
        "uuid": null
      },
      "sda2": {
        "holders": [],
        "links": {
          "ids": [
            "ata-MARVELL_Raid_VD_41d64e2a9e180001-part2"
          ],
          "labels": [],
          "masters": [],
          "uuids": [
            "8a20e768-6056-4aad-90ef-e43f849124ab"
          ]
        },
        "sectors": "2097152",
        "sectorsize": 512,
        "size": "1.00 GB",
        "start": "4096",
        "uuid": "8a20e768-6056-4aad-90ef-e43f849124ab"
      },
      "sda3": {
        "holders": [
          "fedora-swap",
          "fedora-tmp",
          "fedora-var",
          "fedora-root",
          "fedora-var_log",
          "fedora-home"
        ],
        "links": {
          "ids": [
            "ata-MARVELL_Raid_VD_41d64e2a9e180001-part3",
            "lvm-pv-uuid-eimmeA-ppLf-2Ic0-dCbd-sOgh-yv3n-FiOcMy"
          ],
          "labels": [],
          "masters": [
            "dm-0",
            "dm-1",
            "dm-2",
            "dm-3",
            "dm-4",
            "dm-5"
          ],
          "uuids": []
        },
        "sectors": "83902464",
        "sectorsize": 512,
        "size": "40.01 GB",
        "start": "2101248",
        "uuid": null
      },
      "sda4": {
        "holders": [
          "fedora-debug",
          "fedora-images",
          "fedora-var",
          "fedora-root",
          "fedora-repos",
          "fedora-var_log",
          "fedora-home"
        ],
        "links": {
          "ids": [
            "ata-MARVELL_Raid_VD_41d64e2a9e180001-part4",
            "lvm-pv-uuid-x9Kjub-GLK5-n5gE-1zqS-jQUs-JYkh-Hlmyyx"
          ],
          "labels": [],
          "masters": [
            "dm-0",
            "dm-2",
            "dm-3",
            "dm-5",
            "dm-6",
            "dm-7",
            "dm-8"
          ],
          "uuids": []
        },
        "sectors": "7727726815",
        "sectorsize": 512,
        "size": "3.60 TB",
        "start": "86003712",
        "uuid": null
      }
    },
    "removable": "0",
    "rotational": "1",
    "sas_address": null,
    "sas_device_handle": null,
    "scheduler_mode": "bfq",
    "sectors": "7813730560",
    "sectorsize": "512",
    "size": "3.64 TB",
    "support_discard": "0",
    "vendor": "ATA",
    "virtual": 1
  },
```
> ![INFORMATION](../imgs/information-icon.png) El anterior es un ejemplo de la información de un disco de arranque, de sistema operativo, de un sistema Linux.

> ![INFORMATION](../imgs/information-icon.png) Queremos identificar un disco que no esté siendo usado para usarlo en su totalidad para crear un nuevo sistema de ficheros o bien ampliar un Volume Group. Todo esto se puede hacer sobre un disco que aunque no esté libre disponga de espacio libre para crear una partición. El propósito de este ejemplo es ilustrar el uso de facts, no la creación de sistemas de ficheros.

Podemos apreciar en lo anterior que los siguientes campos no se encuentran vacíos:

+ **ansible_facts.ansible_devices.partitions**.

Existen otras variables que pudieran tener contenido en discos que estén siendo utilizados:

```yaml
  "sdd": {
    "holders": [],
    "host": "USB controller: Advanced Micro Devices, Inc. [AMD] FCH USB XHCI Controller (rev 20)",
    "links": {
      "ids": [
        "usb-Generic_Flash_Disk_8F0E713D-0:0"
      ],
      "labels": [
        "backup"
      ],
      "masters": [],
      "uuids": [
        "d7808d28-7c07-41e5-89d6-233e0982fc64"
      ]
    },
    "model": "Flash Disk",
    "partitions": {},
    "removable": "1",
    "rotational": "1",
    "sas_address": null,
    "sas_device_handle": null,
    "scheduler_mode": "bfq",
    "sectors": "16220160",
    "sectorsize": "512",
    "size": "7.73 GB",
    "support_discard": "0",
    "vendor": "Generic",
    "virtual": 1
  },
```

> ![INFORMATION](../imgs/information-icon.png) El anterior es un ejemplo de un sistema de ficheros creado sobre un dispositivo USB. No se ha creado ninguna partición, se ha creado el sistema de ficheros directamente sobre el dispositivo USB.

Los siguientes campos contienen información y no se encuentran vacíos:

+ **ansible_facts.ansible_devices.links.uuids**.
+ **ansible_facts.ansible_devices.links.labels**.

Veamos ahora la información sobre un dispositivo vacío:

```yaml
  "sdb": {
    "holders": [],
    "host": "SATA controller: Marvell Technology Group Ltd. 88SE9230 PCIe 2.0 x2 4-port SATA 6 Gb/s RAID Controller (rev 11)",
    "links": {
      "ids": [
        "ata-ST2000DM006-2DM164_Z4Z9VD3L",
        "wwn-0x5000c500a5df201a"
      ],
      "labels": [],
      "masters": [],
      "uuids": []
    },
    "model": "ST2000DM006-2DM1",
    "partitions": {},
    "removable": "0",
    "rotational": "1",
    "sas_address": null,
    "sas_device_handle": null,
    "scheduler_mode": "bfq",
    "sectors": "3907029168",
    "sectorsize": "512",
    "size": "1.82 TB",
    "support_discard": "0",
    "vendor": "ATA",
    "virtual": 1,
    "wwn": "0x5000c500a5df201a"
  },
```

Podemos ver que esos campos se encuentran vacíos. 
Por lo tanto para detectar los dispositivos vacíos podemos iterar sobre los dispositivos seleccionando aquellos que tengan vacías dichas propiedades.

Para ello, crearemos un fact en el que incluiremos el primer dispositivo libre que encontremos:

```yaml
- name: identifica el primer disco libre
  set_fact:
    disks: "/dev/{{ item.key }}"
  when:
    # si el disco no está particionado tendrá libre 
    # estas variables de los facts
    - not item.value.partitions
    - not item.value.holders
    - not item.value.links.uuids
    - not item.value.links.labels
    # los discos serán /dev/vd? o /dev/sd? filtramos el
    # resto de resultados
    - item.key | regex_search ("vd|sd")
  with_dict: "{{ ansible_devices }}"
```

El playbook [check-for-empty-disk.yaml](check-for-empty-disk.yaml) detecta el primer disco libre, lo almacena en una variable y muestra en pantalla el dispositivo que han encontrado libre:

```yaml
---

- hosts: all
  gather_facts: true

  tasks:
    - name: identifica el primer disco libre
      set_fact:
        disks: "/dev/{{ item.key }}"
      when:
        # si el disco no está particionado tendrá libre 
        # estas variables de los facts
        - not item.value.partitions
        - not item.value.holders
        - not item.value.links.uuids
        - not item.value.links.labels
        # los discos serán /dev/vd? o /dev/sd? filtramos el
        # resto de resultados
        - item.key | regex_search ("vd|sd")
      with_dict: "{{ ansible_devices }}"

    - name: mostrar
      debug: msg="Disco vacio {{ disks }}"
```

> ![INFORMATION](../imgs/information-icon.png) Una vez que tenemos el dispositivo en una variable ya podemos operar con el como necesitemos.

## Resources

+ [Ansible Facts](https://docs.ansible.com/ansible/latest/user_guide/playbooks_vars_facts.html)
+ [Jinja2 templates](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html)
