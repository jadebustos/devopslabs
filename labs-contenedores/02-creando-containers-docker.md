# Creando containers con docker

## Fundamentos docker

Vamos a [DockerHub](https://hub.docker.com/) y buscamos una imagen para descargar.

En categorias seleccionamos **Base Images** y vamos a decargar **busybox**:

```console
[root@lab-docker ~]# docker pull busybox
Using default tag: latest
latest: Pulling from library/busybox
e5d9363303dd: Pull complete 
Digest: sha256:c5439d7db88ab5423999530349d327b04279ad3161d7596d2126dfb5b02bfd1f
Status: Downloaded newer image for busybox:latest
docker.io/library/busybox:latest
[root@lab-docker ~]# 
```

Listamos las imágenes disponibles:

```console
[root@lab-docker ~]# docker images
REPOSITORY   TAG       IMAGE ID       CREATED      SIZE
busybox      latest    b97242f89c8a   4 days ago   1.23MB
[root@lab-docker ~]# 
```

Instanciamos un container a partir de una imagen:

```console
[root@lab-docker ~]# docker run -d busybox
845308bb95594ccbc463c251bd14bb06a65c5d0b8ee4d21ec5bc9c6c1ed8db15
[root@lab-docker ~]# docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
[root@lab-docker ~]#
```
+ **-d** lo arrancamos en background.

Como vemos el contenedor arranca y para.

Instanciamos una nueva imagen, pero esta vez ejecutamos una shell dentro del contendor:

```console
[root@lab-docker ~]# docker run -it --rm busybox
/ #  ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
6: eth0@if7: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue 
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
/ # 
```

+ **--it** indica que abra una sesión interactiva y que le asigne una TTY (terminal).
+ **--rm** indica que se borre la imagen del contendor al terminar.

> ![NOTA](../imgs/note-icon.png) **docker run --help** para ver mas opciones del comando **run**.

Si nos conectamos por ssh a la vm:

```console
[root@lab-docker ~]# docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED         STATUS         PORTS     NAMES
69d24bac6bbb   busybox   "sh"      3 minutes ago   Up 3 minutes             ecstatic_tharp
[root@lab-docker ~]# 
```

Salimos del contenedor y vemos que el contenedor ya no existe:

```console
[root@lab-docker ~]# docker run -d busybox
845308bb95594ccbc463c251bd14bb06a65c5d0b8ee4d21ec5bc9c6c1ed8db15
[root@lab-docker ~]# docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
[root@lab-docker ~]# docker run -it --rm busybox
/ # ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
6: eth0@if7: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue 
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
/ # ps ax
PID   USER     TIME  COMMAND
    1 root      0:00 sh
    7 root      0:00 ps ax
/ # exit
[root@lab-docker ~]# docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
[root@lab-docker ~]#
```

## Creando una imagen simple

Vamos a crear una imagen basada en la imagen **busybox** que va a ejecutar el script [myscript.sh](../ansible/roles/container-examples/files/myscript.sh).

Nos conectamos a la máquina de docker:

```console
[terraform@docker ~]$ sudo su -
Last login: Sun Jan 17 20:42:31 CET 2021 on pts/0
[root@lab-docker ~]# cd build/busibox/
[root@lab-docker busibox]# ls -lh
total 8.0K
-rw-r--r--. 1 root root 99 Jan 17 20:33 Dockerfile
-rw-r--r--. 1 root root 39 Jan 17 20:33 myscript.sh
[root@lab-docker busibox]#
```

El fichero que se encarga de definir la imagen es [Dockerfile](../ansible/roles/container-examples/files/Dockerfile-busybox):

```dockerfile
FROM busybox
MAINTAINER mantainer@email
COPY ./myscript.sh /myscript.sh
RUN chmod +x /myscript.sh
ENTRYPOINT ["/myscript.sh"]
```

```console
[root@lab-docker busybox]# docker build -t mybusybox .
Sending build context to Docker daemon  3.072kB
Step 1/5 : FROM busybox
 ---> b97242f89c8a
Step 2/5 : MAINTAINER mantainer@email
 ---> Running in 837a7764c565
Removing intermediate container 837a7764c565
 ---> e4006f428c2c
Step 3/5 : COPY ./myscript.sh /myscript.sh
 ---> e403a4ff5171
Step 4/5 : RUN chmod +x /myscript.sh
 ---> Running in c5fbd41ef1d0
Removing intermediate container c5fbd41ef1d0
 ---> 41b32057fbfc
Step 5/5 : ENTRYPOINT ["/myscript.sh", "Mundo"]
 ---> Running in a7ca602c8246
Removing intermediate container a7ca602c8246
 ---> 22e286fdd755
Successfully built 22e286fdd755
Successfully tagged mybusybox:latest
[root@lab-docker busybox]# docker images
REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
mybusybox    latest    22e286fdd755   12 seconds ago   1.23MB
busybox      latest    b97242f89c8a   4 days ago       1.23MB
[root@lab-docker busybox]# 
```

Ejecutamos un container basado en esa imagen:

```console
[root@lab-docker busybox]# docker run -d mybusybox 
811ba76fb030e02b90aeb3e1e9f047b174b30cb012310d8665374a10c7fbafb6
[root@lab-docker busybox]# docker ps ; sleep 30
CONTAINER ID   IMAGE       COMMAND                CREATED         STATUS        PORTS     NAMES
811ba76fb030   mybusybox   "/myscript.sh Mundo"   3 seconds ago   Up 1 second             silly_hugle
[root@lab-docker busybox]# docker ps ; sleep 20
CONTAINER ID   IMAGE       COMMAND                CREATED          STATUS          PORTS     NAMES
811ba76fb030   mybusybox   "/myscript.sh Mundo"   36 seconds ago   Up 34 seconds             silly_hugle
[root@lab-docker busybox]# docker ps ; sleep 10
CONTAINER ID   IMAGE       COMMAND                CREATED          STATUS          PORTS     NAMES
811ba76fb030   mybusybox   "/myscript.sh Mundo"   59 seconds ago   Up 57 seconds             silly_hugle
[root@lab-docker busybox]# docker ps ; sleep 10
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
[root@lab-docker busybox]# 
```

Podemos observar que después de unos segundos, 60, termina la ejecución del contenedor.

Cambiemos **myscript.sh** por **myinfinitescript.sh** en el [Dockerfile](../ansible/roles/container-examples/files/Dockerfile-busybox) de tal forma que:

```dockerfile
FROM busybox 
MAINTAINER mantainer@email
COPY ./myinfinitescript.sh /myinfinitescript.sh
RUN chmod +x /myinfinitescript.sh
ENTRYPOINT ["/myinfinitescript.sh"]
```

Donde **myinfinitescript.sh**:

```bash
#!/bin/sh

while true
do
  echo "Random string: "$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
  sleep 5  
done
```

Construyamos el contenedor y ejecutemoslo:

```console
[root@lab-docker busybox]# docker build -t mybusybox .
...
[root@lab-docker busybox]# docker run -d mybusybox 
bfe8f9c45c6f8319d67192f9778e53479d6d89b9432fcc4c0825da1a804b5a9d
[root@lab-docker busybox]# docker ps
CONTAINER ID   IMAGE       COMMAND                  CREATED         STATUS         PORTS     NAMES
bfe8f9c45c6f   mybusybox   "/myinfinitescript.sh"   7 seconds ago   Up 5 seconds             fervent_shannon
[root@lab-docker busybox]# 
```

## Troubleshooting

Cuando tenemos problemas o el contenedor no funciona como debería para realizar troubleshooting ya hemos visto una forma, que es ejecutar una shell en el contenedor. Pero existen otras alternativas.

Podemos atacharnos al contenedor en ejecución y ver la salida estándar para sacar información de que está pasando:

```console
[root@lab-docker busybox]# docker ps
CONTAINER ID   IMAGE       COMMAND                  CREATED         STATUS         PORTS     NAMES
bfe8f9c45c6f   mybusybox   "/myinfinitescript.sh"   7 seconds ago   Up 5 seconds             fervent_shannon
[root@lab-docker busybox]# docker attach bfe8f9c45c6f8319d67192f9778e53479d6d89b9432fcc4c0825da1a804b5a9d
Random string: 1FqVNoGKd0FiuKm5j8fwOZ4NtbW9RcdM7JhRkQLueaM73kDLkbMEQRruopOuxDVr
Random string: JeXHBYLr4lKpgbrcyOKffmTE0zIiWnyUHBJXEC6WrbAM9hpHCMPzQfpLz6dJYW9O
Random string: ndQnfm1lIUYMxp8h44SGkFjP8oU8uPDo3seas6yaCNaVaczghpJNinv0Mj8TfQEx
Random string: 5cWJdAhpzXlMV297zSKuhPRKCpPcrjXWg9NEH1EmXyv7j7lZ8t4XN8H4RTJn8rN8
Random string: ytP2cWvcUmSCELpofuX7e3t7XDML2690LMq00etKc0DtVWMKFiv7qa81UwzOtgXq
Random string: HIkAElMp4iCdHiClAAYB7xTNJiEW3ezzL5uLfjiwauJcYMfsRspcrXcOlFb0HoyF
...
```

Para salir pulsar **Ctrl + c** saldremos, pero la ejecución del contenedor habrá terminado ya que hemos terminado el proceso al que nos hemos conectado.


Para por salir y que el contenedor se siga ejecutando:

```console
[root@lab-docker busybox]# docker run -itd mybusybox 
96a78b06124be8face69201260e435ed8957eeb43bf28e9462aed2b2c436360e
[root@lab-docker busybox]# docker attach 96a78b06124be8face69201260e435ed8957eeb43bf28e9462aed2b2c436360e
Random string: gfvtNJtcrXFtSOYIIUDdWGJvrCKBEGkz8Y2gvLXBuaJA5Tc4MW5Vhh8DQStV6a7n
Random string: BPVsfEilXRJiEZbqPBK4zMTCVp9zTdCT8isESN8csAfMN0mCh6BYyaRYn44532su
Random string: Iw7wYgSqYuwV80ZRpg7xkBOElZWN7aavXm6Z1jUHq6WvVjivL2cNAyRy0jxE5uYU
```

Pulsamos **Ctrl + p** y **Ctrl + q**:

```console
read escape sequence
[root@lab-docker busybox]# docker ps
CONTAINER ID   IMAGE       COMMAND                  CREATED          STATUS          PORTS     NAMES
96a78b06124b   mybusybox   "/myinfinitescript.sh"   33 seconds ago   Up 31 seconds             bold_mendeleev
[root@lab-docker busybox]# 
```

Podemos ejecutar una shell:

```console
[root@lab-docker apache]# docker exec -it 4f94e272bac8 bash
root@4f94e272bac8:/var/www/html# 
```

Para salir de la shell bastaría con ejecutar **exit**:

```console
root@4f94e272bac8:/var/www/html# exit
exit
[root@lab-docker apache]#
```

Para ver el historial de lo que ha pasado en el contenedor:

```console
[root@lab-docker busybox]# docker logs 96a78b06124be8face69201260e435ed8957eeb43bf28e9462aed2b2c436360e
Random string: GiJ4o2tiOs42keRyu8xjKXQQVct67wCopuamOSPcQ9DSBIy7PkrsiIfDodCVdJZF
Random string: e9a6GxKpeJjyJAGv2Mp5DMLpvT2myVBNooBlOl6UnNYDvzmI7pYhumGqFhCAtHD8
Random string: Lb6NNYkz0JeTZ8FccU0yDT9FLKYW2jzOv6FksmbQu1VXfzZFa6TWNlQMthjiT4ab
Random string: gfvtNJtcrXFtSOYIIUDdWGJvrCKBEGkz8Y2gvLXBuaJA5Tc4MW5Vhh8DQStV6a7n
Random string: BPVsfEilXRJiEZbqPBK4zMTCVp9zTdCT8isESN8csAfMN0mCh6BYyaRYn44532su
Random string: Iw7wYgSqYuwV80ZRpg7xkBOElZWN7aavXm6Z1jUHq6WvVjivL2cNAyRy0jxE5uYU
Random string: InyatlYTSrC6Dottvwjws0IozJJ11zD45OQw0L9lO9QhIreyXYArmc8wuP2BOzoX
Random string: 7Ary71cibAgDbvTS5not5ZOp2t6Fch2jzRyNtMgu8f8Q2jmn4o552yymAtwVpul2
Random string: t4JlqQ8yj0Wy4nWesi79kBZrUdBWuIZg3U2IFTbbwE2kqhoNNvdqMRzyACqwkSgh
Random string: 4Sc8cqITMhInIxM1XUwbFgT6MzRTVkbG4rTt5koDMBl2qIQwZPFZ42ExWrnpEycY
Random string: LFvfgafd1fos6nIl9shI6bxudQ4At9ujjFKKNPZYFpMdJOQytIZ71LlYUj9agcBj
Random string: kMnIIKY73vrSOQk3ucVjeXcrnqVlJ0PnJkDa323IBgLbPLby4mSlSx2Msmxbfkq7
Random string: l9TTO1o9laZTwpyKMLLnCgridpGC2Ska0gP4fQGHqUW1kDHGRQD2nBGvZnDqfGLA
Random string: Be0l69MY2aBQgX5DIpEks2JMnYNBWjvFZIftLlW83pitHsEZVC5m5N3hGNEVKoip
Random string: G6SwOzNkGBvey6OiZDgnDsgINMopMYvPcJHUEWcWWiNhPgCC34vBhkY8AH1RHEmH
Random string: R5OrABZBZgYhdrGgizGfbqtmMSAhC9yJetjrJ10gi7odo5aWEmsFdg5g6LYv3Yfd
Random string: J2JeDIGq6lspv9Q9HeTBGCAJF191MEKHaTdmtrE8Z2abPOvtXQKmaXTh2ktzHUYg
Random string: yeBz8m5WlTkq8jAYMoJI3CkGeXjbVdQ8E2lTOhcqFhuoJbU0mxmj9XZqIzzWLBR4
Random string: yVnxX20hB9PMfhOukOu0Akq5wFpDdcA3vrnvyooW70e4fFbeThuOhCVkdk5py3UA
Random string: I1vWYHKTxRYmYe8usRxIssjv2C1ZS5DGzUePB7pa3Kp3kqI6SQdvfs7e5zF2yhvr
Random string: mcUx02kt7j4SXCrC0D4kLXlus3vTubmf6LjqOdp8q7dFJSpbwtRWDAfJX6vI3SbE
Random string: 0PFnfm2SwvVXfdYrLUEexBfrngs09FFyQmNcL3rnVkNbMnpMRgzfgB2tYWwTmhIw
Random string: nXtHpev41jd0TsAAVg40npVblLjPrlOKmmFiy9v0kAVTAW2eQWfpRjAKVLoa33ZJ
Random string: puCssoQmlzvgLUxwxrU9V3uLW02lVSebOAQk34KU1kIqaU60KDy5BP1OgZMDneij
Random string: thisAXlTGaREXt4UoWyYAm0Eg7F5AmYUG0Q6TYrBYCusMHb4PsSBZzQ0Qj2KBls1
Random string: SKJx2SH37iWhFvV3pWDtrqWa0HIH6Dcv0UgjLFQok5VuMrbVe9RaX4vjkLF1vhSu
Random string: ui1X0qQCJsimqZY1GLijqtJN5d6RvY8q8q00MsXM6iA7g58EzoKjC5NZUyk9M8Yn
Random string: G7S14jK0KWCI7pGeZF2O8pItezZoIJSIAqFmbCWwjOWAuSkXRFnzeS7fV0IUOexw
Random string: 2SqFlYEikfh5abZ6y1PRZuT63lzYEnANxdMnlaweoFp9J2WYsXq1B5M4ToU6jL6T
Random string: PTVOhBRbOLAwrvR33qLSFts3J3PnAKlERdGtKANAGFmqNwItPHgkuBNN4tKD9RsG
Random string: q3z4MyW609AYFnnXMj8Xq535HEtQn4kzMYqlLe4dzC0PVZabJsYnUbTUlt1qYAF5
Random string: 0rGojXT0iTVT7zNw42CqGHppgTGPdLbh9M2DMqMDnhTSS4ZPsv0Up0vn9CIRvzWc
Random string: MsXMTZytA2J4Lqsm6UcEe7G9aZf9eAVuagA2thbPIbDfGn1eQIawxkVgfWFDYdxv
Random string: XDRdjZ9wxegATZTRKI7cli9C1PUaooJjDxxOkU9Q7zXDslkxEzc3AOUdiIPwPex1
Random string: NnOfePw2lHeUQfsQC0okelH7BgGWrIDvlDyrgNFQkGO2xcG7ea2Uq9eaBMVi9Zv1
Random string: qRVtuGfSgIQaJlDXus1qcQF8wCSFrs5KJMfRpoIjlNhsKKA788znCfah6fKVSiVB
Random string: deGqL5WHgOcPgkidZCDOBfOtQJw8TRlDB88udTmF9ePZoO5VzuMnyjuYTGTXugx1
Random string: CQ1qUylkPgepUu3Qn1USCeltWRxm843x6zH601jjXFKu9457GSZ3MruTbfMsfUtM
Random string: TX0ypA0gtuzcmx5WahNhDpJ4AaR6GHWDpMHJimHM1cNUSpVfiUZ67degBfOemMDl
Random string: TLKr3flGaPrPkeiwE06UCJu59yJScSN1BUahw3cmO4OnPavYitGYMnXCK9s1IRiN
[root@lab-docker busybox]# 
```

## Arrancando parando contenedores contenedores

+ **docker start <container>** arranca un container ya existente.
+ **docker stop <container>** para de forma ordenada un container en ejecución.
+ **docker kill <container>** para un container en ejecución de una forma no ordenada.

```console
[root@lab-docker busybox]# docker ps
CONTAINER ID   IMAGE       COMMAND                  CREATED         STATUS         PORTS     NAMES
96a78b06124b   mybusybox   "/myinfinitescript.sh"   4 minutes ago   Up 4 minutes             bold_mendeleev
[root@lab-docker busybox]# docker kill 96a78b06124b
96a78b06124b
[root@lab-docker busybox]# docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
[root@lab-docker busybox]#
```

## Mapeando volúmenes

Nos conectamos a la máquina de docker:

```console
[terraform@docker ~]$ sudo su -
Last login: Sun Jan 17 20:42:31 CET 2021 on pts/0
[root@lab-docker ~]# cd build/apache/
[root@lab-docker apache]# ls -lh
total 8.0K
-rw-r--r--. 1 root root 99 Jan 17 20:33 Dockerfile
-rw-r--r--. 1 root root 39 Jan 17 20:33 myscript.sh
[root@lab-docker apache]#
```

Vamos a crear una aplicación web. El [Dockerfile](../ansible/roles/container-examples/files/Dockerfile):

```dockerfile
FROM php:7-apache
MAINTAINER mantainer@email
ENV PORT=80
COPY virtualhost.conf /etc/apache2/sites-available/000-default.conf
COPY index.php /var/www/public/index.php
COPY start-apache.sh /usr/local/bin/start-apache
RUN chown -R www-data:www-data /var/www
RUN chmod 755 /usr/local/bin/start-apache
ENTRYPOINT ["start-apache"]
```

Construimos la imagen:

```console
[root@lab-docker apache]# docker build -t webapp .
...
Successfully built 68d34ba47136
Successfully tagged webapp:latest
[root@lab-docker apache]# docker images
REPOSITORY   TAG        IMAGE ID       CREATED          SIZE
webapp       latest     64b48d2b2956   16 seconds ago      414MB
<none>       <none>     68d34ba47136   15 minutes ago      414MB
mybusybox    latest     4020b434e17a   42 minutes ago      1.23MB
<none>       <none>     22e286fdd755   About an hour ago   1.23MB
busybox      latest     b97242f89c8a   4 days ago          1.23MB
php          7-apache   2d5d57e31bd0   5 days ago          414MB
[root@lab-docker apache]#
```

> ![INFORMATION](../imgs/information-icon.png) [Buenas prácticas para crear imágenes de containers](https://docs.openshift.com/container-platform/4.6/openshift_images/create-images.html). Aunque se centra en OpenShift es aplicable a cualquier tecnología de contenedores OCI.

Creamos un container a partir de la imagen:

```console
[root@lab-docker apache]# docker run -itd webapp 
b3e62591ee8b8e290a43b4f1340b20d5931e0fe989f3ff8eb7c51dc2d7933eaf
[root@lab-docker apache]# docker ps
CONTAINER ID   IMAGE     COMMAND          CREATED         STATUS         PORTS     NAMES
b3e62591ee8b   webapp    "start-apache"   6 seconds ago   Up 4 seconds   80/tcp    nervous_nightingale
[root@lab-docker apache]# 
```

Ahora que tenemos el contenedor corriendo obtenemos su ip:

```console
[root@lab-docker apache]# docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' f90ff30a811d
172.17.0.2
[root@lab-docker apache]# 
```

> ![TIP](../imgs/tip-icon.png) **docker inspect CONTAINER**

En linux existe una utilidad llamada **jq** que nos permite extraer información de un json. No se suele instalar por defecto, normalmente el paquete se llama **jq**. Si está instalada:

```console
[root@lab-docker apache]# docker inspect f90ff30a811d | jq '.[] | .NetworkSettings.Networks.bridge.IPAddress'
172.17.0.2
[root@lab-docker apache]# 
```

Como la salida de inspect nos devuelve un array de jsons mediante **.[]** indicamos que va a procesar un array y con el pipe, **|**, le indicamos la propiedad que queremos ver. En este caso el array solo tiene un json, por lo tanto la salida será una única ip.

Si solo quisiéramos procesar un elemento bastaría con poner el índice del elemento a procesar entre los corchetes, por ejemplo **[0]** solo procesaría el primer elemento de array.

Ejecutamos en la consola

```console
[root@lab-docker apache]# elinks http://172.17.0.2
```

y podremos navegar por la aplicación.

Estamos acceciendo a una url interna de docker, el puerto no se encuentra expuesto. Si queremos que sea accesible desde el exterior tendremos que exponerlo:

```console
[root@lab-docker apache]# docker run -tid -p 8080:80 --name apache_server3 --rm webapp
65dd77308916c2b3b396c6dcdd2a2d4252e36e58b334c47c84830db00fe4549b
[root@lab-docker apache]# docker ps
CONTAINER ID   IMAGE     COMMAND          CREATED              STATUS              PORTS                  NAMES
65dd77308916   webapp    "start-apache"   About a minute ago   Up About a minute   0.0.0.0:8080->80/tcp   apache_server3
[root@lab-docker apache]# 
```

Ahora la aplicación será accesible por el puerto **8080** a través de la ip de docker.frontend.lab:

```console
[jadebustos@beast apache]$ links2 http://lab-docker.frontend.lab:8080
```
Cuando mapeamos un puerto docker incluye una regla en IPTABLES para permitir el tráfico y se encargar del reenvio del tráfico entre los puertos:

```console
[root@lab-docker apache]# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain FORWARD (policy DROP)
target     prot opt source               destination         
DOCKER-ISOLATION-STAGE-1  all  --  anywhere             anywhere            
ACCEPT     all  --  anywhere             anywhere             ctstate RELATED,ESTABLISHED
DOCKER     all  --  anywhere             anywhere            
ACCEPT     all  --  anywhere             anywhere            
ACCEPT     all  --  anywhere             anywhere            
DOCKER-USER  all  --  anywhere             anywhere            

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         

Chain DOCKER (1 references)
target     prot opt source               destination         
ACCEPT     tcp  --  anywhere             172.17.0.2           tcp dpt:http

Chain DOCKER-ISOLATION-STAGE-1 (1 references)
target     prot opt source               destination         
RETURN     all  --  anywhere             anywhere            

Chain DOCKER-ISOLATION-STAGE-2 (0 references)
target     prot opt source               destination         
RETURN     all  --  anywhere             anywhere            

Chain DOCKER-USER (1 references)
target     prot opt source               destination         
RETURN     all  --  anywhere             anywhere            
[root@lab-docker ~]# 
```

```console
[root@lab-docker apache]# docker run -tid -p 8080:80 --rm --name apache_server3 -v /root/build/apache/custom-php/:/var/www/public:Z webapp
9480bd0725a2753f70786e308c4697fa6e111b05e7e45e9d9f9d24f6b416fb0e
[root@lab-docker apache]# docker ps
CONTAINER ID   IMAGE     COMMAND          CREATED         STATUS         PORTS                  NAMES
9480bd0725a2   webapp    "start-apache"   5 seconds ago   Up 4 seconds   0.0.0.0:8080->80/tcp   apache_server3
[root@lab-docker apache]#
```

+ **-v /root/build/apache/custom-php/:/var/www/public:Z** si la máquina que ejecuta el engine de containers, docker en este caso, tiene SELinux activado se debe utilizar **:Z** para que el contenedor internamente se etiquete con el contexto de SELinux que se ejecuta el contenedor y de esta forma evitar que SELinux bloquee el correcto funcionamiento.

> ![INFORMATION](../imgs/information-icon.png) [Volumes](https://docs.docker.com/storage/volumes/)

> ![INFORMATION](../imgs/information-icon.png) [Bind Mounts](https://docs.docker.com/storage/bind-mounts/)

Como hemos definido una variable de entorno en el Dockerfile podemos utilizarla para parametrizaciones dentro del container:

```console
[root@lab-docker apache]# export PORT=789
[root@lab-docker apache]# docker run -itd --env PORT -p 8080:$PORT -v /root/build/apache/custom-php/:/var/www/public:Z webapp
17f28f4e7fe6b4418535b28a2534f4b2f675c6593cba9c5684a21a8b2aea8f48
[root@lab-docker apache]# docker ps
CONTAINER ID   IMAGE     COMMAND          CREATED         STATUS         PORTS                           NAMES
17f28f4e7fe6   webapp    "start-apache"   5 seconds ago   Up 4 seconds   80/tcp, 0.0.0.0:8080->789/tcp   suspicious_babbage
[root@lab-docker apache]# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain FORWARD (policy DROP)
target     prot opt source               destination         
DOCKER-USER  all  --  anywhere             anywhere            
DOCKER-ISOLATION-STAGE-1  all  --  anywhere             anywhere            
ACCEPT     all  --  anywhere             anywhere             ctstate RELATED,ESTABLISHED
DOCKER     all  --  anywhere             anywhere            
ACCEPT     all  --  anywhere             anywhere            
ACCEPT     all  --  anywhere             anywhere            

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         

Chain DOCKER (1 references)
target     prot opt source               destination         
ACCEPT     tcp  --  anywhere             172.17.0.2           tcp dpt:789

Chain DOCKER-ISOLATION-STAGE-1 (1 references)
target     prot opt source               destination         
DOCKER-ISOLATION-STAGE-2  all  --  anywhere             anywhere            
RETURN     all  --  anywhere             anywhere            

Chain DOCKER-ISOLATION-STAGE-2 (1 references)
target     prot opt source               destination         
DROP       all  --  anywhere             anywhere            
RETURN     all  --  anywhere             anywhere            

Chain DOCKER-USER (1 references)
target     prot opt source               destination         
RETURN     all  --  anywhere             anywhere            
[root@lab-docker apache]#
```

La aplicación mostrará algo así:

![webapp](imgs/webapp.png)

## Publicando imágenes

Vamos a [Docker Hub](https://hub.docker.com/) y nos creamos una cuenta si no tenemos ya una.

Creamos un repositorio público.

Para subir una imagen a nuestro repositorio:

```console
[root@lab-docker apache]# docker images
REPOSITORY   TAG        IMAGE ID       CREATED         SIZE
webapp       latest     93e345f66e51   4 minutes ago   414MB
mybusybox    latest     a0bf925745fb   8 minutes ago   1.23MB
busybox      latest     b97242f89c8a   5 days ago      1.23MB
php          7-apache   2d5d57e31bd0   6 days ago      414MB
[root@lab-docker apache]# docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: jadebustos2
Password: 
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
[root@lab-docker apache]# docker push mybusybox
Using default tag: latest
The push refers to repository [docker.io/library/mybusybox]
dacf42e9f49b: Preparing 
d4fd88d16ef3: Preparing 
0064d0478d00: Preparing 
denied: requested access to the resource is denied
[root@lab-docker apache]# 
```

Por defecto está intentando subirla al repositorio público y no al nuestro. Por ese motivo falla. Necesitamos tagearla apropiadamente:

```console
[root@lab-docker apache]# docker tag mybusybox jadebustos2/devops
[root@lab-docker apache]# docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
[root@lab-docker apache]# docker images
REPOSITORY           TAG        IMAGE ID       CREATED          SIZE
webapp               latest     93e345f66e51   15 minutes ago   414MB
jadebustos2/devops   latest     a0bf925745fb   18 minutes ago   1.23MB
mybusybox            latest     a0bf925745fb   18 minutes ago   1.23MB
busybox              latest     b97242f89c8a   5 days ago       1.23MB
php                  7-apache   2d5d57e31bd0   6 days ago       414MB
[root@lab-docker apache]# docker push jadebustos2/devops
Using default tag: latest
The push refers to repository [docker.io/jadebustos2/devops]
dacf42e9f49b: Pushed 
d4fd88d16ef3: Pushed 
0064d0478d00: Mounted from library/busybox 
latest: digest: sha256:af02a8c911c69c7137bb41b1dc72daf9981eaa98bb3af0467b70f0e10732918a size: 941
[root@lab-docker apache]# 
```

La imagen se encontrará disponible en [DockerHub](https://hub.docker.com/u/jadebustos2).

Si quisieramos descargarla desde docker:

```console
[root@host ~]# docker pull jadebustos2/devops:latest
```

También podríamos añadir tags:

```console
[root@lab-docker apache]# docker tag mybusybox jadebustos2/devops:v1
[root@lab-docker apache]# docker push jadebustos2/devops:v1
```

## Exportando imágenes

**docker save** redirige a la salida estándar por defecto pero se puede redirigir a un archivo:

```console
[root@lab-docker apache]# docker images
REPOSITORY           TAG        IMAGE ID       CREATED          SIZE
webapp               latest     93e345f66e51   33 minutes ago   414MB
jadebustos2/devops   latest     a0bf925745fb   36 minutes ago   1.23MB
mybusybox            latest     a0bf925745fb   36 minutes ago   1.23MB
busybox              latest     b97242f89c8a   5 days ago       1.23MB
php                  7-apache   2d5d57e31bd0   6 days ago       414MB
[root@lab-docker apache]# docker save -o webapp.tar webapp
[root@lab-docker apache]# ls -lh
total 404M
drwxr-xr-x. 2 root root   23 Jan 18 16:07 custom-php
-rw-r--r--. 1 root root  312 Jan 18 16:07 Dockerfile
-rw-r--r--. 1 root root  116 Jan 18 16:07 index.php
-rw-r--r--. 1 root root  163 Jan 18 16:07 start-apache.sh
-rw-r--r--. 1 root root  218 Jan 18 16:07 virtualhost.conf
-rw-------. 1 root root 404M Jan 18 16:46 webapp.tar
[root@lab-docker apache]# 
```

**docker save** actua sobre la imagen de un container.

Podemos utilizar **docker load** para subir al engine un contenedor desde la salida estándar o desde un fichero tar.

Podemos exportar e importar filesystems de contenedores mediante **docker export** y **docker import**:

```console
[root@lab-docker apache]# docker export 17f28f4e7fe6 -o webapp.tar
[root@lab-docker apache]# ls -lh
total 398M
drwxr-xr-x. 2 root root   23 Jan 18 17:47 custom-php
-rw-r--r--. 1 root root  325 Jan 18 17:28 Dockerfile
-rw-r--r--. 1 root root  116 Jan 18 16:07 index.php
-rw-r--r--. 1 root root  165 Jan 18 17:18 start-apache.sh
-rw-r--r--. 1 root root  219 Jan 18 17:11 virtualhost.conf
-rw-------. 1 root root 398M Jan 18 18:05 webapp.tar
[root@lab-docker apache]#
```