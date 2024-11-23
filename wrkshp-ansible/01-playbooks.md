# Playbooks

Para ejecutar tareas en ansible escribiremos playbooks. Aunque es posible incluir todas las tareas en un único playbook como en [generate-linux-pass-hash.yaml](generate-linux-pass-hash.yaml) lo recomendable es escribir roles para poder reutilizarlos.

En el playbook anterior podemos ver:

+ Almacenar la salida de un comando en una variable, para utilizarla mas adelante.
+ Permitir al usuario introducir información por teclado.
+ Ejecutar tareas en el equipo donde se ejecuta ansible sin tener que realizar conexiones SSH.

```console
[jadebustos@archimedes labs-ansible]$ ansible-playbook -i hosts generate-linux-pass-hash.yaml 
Introduce una contraseña para generar el hash: 

PLAY [localhost] *****************************************************************************************************************************************************************************************************************************

TASK [generamos un valor aleatorio como salt para generar la contraseña] *********************************************************************************************************************************************************************
changed: [localhost]

TASK [creamos el hash (sha512)] **************************************************************************************************************************************************************************************************************
changed: [localhost]

TASK [debug] *********************************************************************************************************************************************************************************************************************************
ok: [localhost] => {
    "msg": "El hash del password introducido es $6$2FWHee0JFh9gUZFR$z72.TcPg4epTlJmoUVDyuHpHnmQAOgmHoWlJl4T4vRMIwprdlgx6Pw9G6FPlsiKJu/W9JdrWjMHOKeY/HYxhL0"
}

PLAY RECAP ***********************************************************************************************************************************************************************************************************************************
localhost                  : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

[jadebustos@archimedes labs-ansible]$
```