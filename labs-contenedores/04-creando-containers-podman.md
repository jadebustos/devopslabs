# Gestión de containers con podman, buildah y skopeo

**Docker** se utiliza para toda la gestión de los contendores.

Sin embargo con **podman**, **buildah** y **skopeo** tenemos distribuida la gestión de los contenedores. Cada una de estas herramientas está especializada.

## Construyendo imágenes con buildah

Iniciamos sesión y lo primero que deberemos hacer es editar el fichero **/etc/containers/registries.conf** y dejar únicamente el registry de docker:

```
[registries.search]
#registries = ['registry.access.redhat.com', 'registry.redhat.io', 'docker.io']
registries = ['docker.io']
```

De esta forma solo hará pull al registry de docker cuando necesite buscar una imagen y no se indique ningún registry.

Vamos a un directorio que incluya un Dockerfile:

```console
[terraform@lab-podman ~]$ sudo su -
Last login: Mon Jan 18 12:09:22 CET 2021 on pts/0
[root@lab-podman ~]# cd build/
apache/  busybox/ 
[root@lab-podman ~]# cd build/apache/
[root@lab-podman apache]#
```

Para construir el container:

```console
[root@lab-podman apache]# buildah bud -t webapp .
STEP 1: FROM php:7-apache
Getting image source signatures
Copying blob 60b09083723b done  
Copying blob 657d9d2c68b9 done  
Copying blob 02bab8795938 done  
Copying blob 2b62153f094c done  
Copying blob a076a628af6f done  
Copying blob f47b5ee58e91 done  
Copying blob bae0c4dc63ea done  
Copying blob a1c05958a901 done  
Copying blob 1701d4d0a478 done  
Copying blob 17c19430ed9f done  
Copying blob 5964d339be93 done  
Copying blob 1c16920b970c done  
Copying blob 1fab8f583d66 done  
Copying config 2d5d57e31b done  
Writing manifest to image destination
Storing signatures
STEP 2: MAINTAINER mantainer@email
STEP 3: COPY virtualhost.conf /etc/apache2/sites-available/000-default.conf
STEP 4: COPY index.php /var/www/public/index.php
STEP 5: COPY start-apache.sh /usr/local/bin/start-apache
STEP 6: RUN chown -R www-data:www-data /var/www
STEP 7: RUN chmod 755 /usr/local/bin/start-apache
STEP 8: ENTRYPOINT ["start-apache"]
STEP 9: COMMIT webapp
Getting image source signatures
Copying blob cb42413394c4 skipped: already exists  
Copying blob 708ba1e65ea2 skipped: already exists  
Copying blob 21e4fbf5d49d skipped: already exists  
Copying blob eab592dd1e81 skipped: already exists  
Copying blob 4d2fe5e049cd skipped: already exists  
Copying blob 0f4870748e56 skipped: already exists  
Copying blob ca4d8bf00bbd skipped: already exists  
Copying blob c538285c2d9c skipped: already exists  
Copying blob 37e93e7f1fb8 skipped: already exists  
Copying blob 895d27070d31 skipped: already exists  
Copying blob c71c843a86c0 skipped: already exists  
Copying blob 3c8da4534dcd skipped: already exists  
Copying blob 3963c67cce6c skipped: already exists  
Copying blob 4c2577661034 done  
Copying config 09550857c8 done  
Writing manifest to image destination
Storing signatures
--> 09550857c85
09550857c857f0661ba0913b32a477034af061a10579cf12501e5c95d49233e1
[root@lab-podman apache]# 
```

Una vez construida podemos ver si se ha creado:

```console
[root@lab-podman apache]# buildah images
REPOSITORY              TAG        IMAGE ID       CREATED         SIZE
localhost/webapp        latest     09550857c857   2 minutes ago   423 MB
docker.io/library/php   7-apache   2d5d57e31bd0   6 days ago      423 MB
[root@lab-podman apache]#
```

Levantamos un contenedor basado en la imagen **webapp**:

```console
[root@lab-podman apache]# export PORT=80
[root@lab-podman apache]# podman run -itd --env PORT -p 8080:$PORT -v /root/build/apache/custom-php/:/var/www/public:Z webapp
725e11ce8314c10e6b628c92f5c91fd074546232ba2c9af052b9f8b0f24ee936
[root@lab-podman apache]# podman ps
CONTAINER ID  IMAGE                    COMMAND  CREATED        STATUS            PORTS                 NAMES
725e11ce8314  localhost/webapp:latest           7 seconds ago  Up 6 seconds ago  0.0.0.0:8080->80/tcp  sharp_curie
[root@lab-podman apache]#
```

| Engine | Comando |
---------|---------
| Docker | docker run -itd --env PORT -p 8080:$PORT -v /root/build/apache/custom-php/:/var/www/public:Z webapp |
| Podman | podman run -itd --env PORT -p 8080:$PORT -v /root/build/apache/custom-php/:/var/www/public:Z webapp |


> ![INFORMATION](../imgs/information-icon.png) [buildahimage](https://github.com/containers/buildah/tree/master/contrib/buildahimage)

> ![INFORMATION](../imgs/information-icon.png) [Getting started with buildah](https://developers.redhat.com/blog/2021/01/11/getting-started-with-buildah/)

> ![INFORMATION](../imgs/information-icon.png) [Podman and buildah for docker users](https://developers.redhat.com/blog/2019/02/21/podman-and-buildah-for-docker-users/)

> ![INFORMATION](../imgs/information-icon.png) [Best practices for running buildah in a container](https://developers.redhat.com/blog/2019/08/14/best-practices-for-running-buildah-in-a-container/)

> ![INFORMATION](../imgs/information-icon.png) [Build and run buildah inside a podman container](https://developers.redhat.com/blog/2019/04/04/build-and-run-buildah-inside-a-podman-container/)

## Podman

Todo lo visto para la ejecución de contenedores aplica a **podman**, basta con cambiar **docker** por **podman**.

Por ejemplo, para descargase una imagen:

```console
[root@lab-podman apache]# podman pull busybox
Completed short name "busybox" with unqualified-search registries (origin: /etc/containers/registries.conf)
Trying to pull docker.io/library/busybox:latest...
Getting image source signatures
Copying blob e5d9363303dd done  
Copying config b97242f89c done  
Writing manifest to image destination
Storing signatures
b97242f89c8a29d13aea12843a08441a4bbfc33528f55b60366c1d8f6923d0d4
[root@lab-podman apache]# podman images
REPOSITORY                 TAG       IMAGE ID      CREATED         SIZE
localhost/webapp           latest    e5d17b255420  39 seconds ago  423 MB
docker.io/library/busybox  latest    b97242f89c8a  5 days ago      1.45 MB
docker.io/library/php      7-apache  2d5d57e31bd0  6 days ago      423 MB
[root@lab-podman apache]# 
```

> ![INFORMATION](../imgs/information-icon.png) [Podman for docker users](https://dzone.com/articles/podman-for-docker-users)

> ![INFORMATION](../imgs/information-icon.png) [Transitioning from docker to podman](https://developers.redhat.com/blog/2020/11/19/transitioning-from-docker-to-podman/)

## Subiendo imágenes con podman a un repositorio remoto

Podemos subir imágenes a un repositorio con podman, para ello deberemos sacar una cuenta en [quay](https://quay.io). Una vez creada iniciamos sesión:

```console
[root@lab-podman ~]# podman login quay.io
Username: rhte_2019
Password: 
Login Succeeded!
[root@lab-podman ~]# 
```

Etiquetamos la imagen local que tenemos para subirla a **quay.io** usando tags y hacemos push:

```console
[root@lab-podman ~]# podman images
REPOSITORY                    TAG       IMAGE ID      CREATED      SIZE
localhost/webapp              latest    251ed3cc660d  17 minutes ago  423 MB
docker.io/library/php         7-apache  899ab23566b7  2 days ago      423 MB
docker.io/library/busybox     latest    b97242f89c8a  11 days ago     1.45 MB
[root@lab-podman ~]# podman tag localhost/webapp quay.io/rhte_2019/webapp:v1
[root@lab-podman ~]# podman images
REPOSITORY                    TAG       IMAGE ID      CREATED         SIZE
quay.io/rhte_2019/webapp      v1        251ed3cc660d  19 minutes ago  423 MB
localhost/webapp              latest    251ed3cc660d  19 minutes ago  423 MB
docker.io/library/php         7-apache  899ab23566b7  2 days ago      423 MB
docker.io/library/busybox     latest    b97242f89c8a  11 days ago     1.45 MB
[root@lab-podman ~]# podman push quay.io/rhte_2019/webapp:v1
...
[root@lab-podman ~]# 
```

## Skopeo

Con skopeo podemos ver metadatos de las imágenes sin tener que descargarlas. Por ejemplo para la imagen que se subió antes a **DockerHub**:

```console
[root@lab-podman ~]# skopeo inspect docker://docker.io/jadebustos2/devops
{
    "Name": "docker.io/jadebustos2/devops",
    "Digest": "sha256:af02a8c911c69c7137bb41b1dc72daf9981eaa98bb3af0467b70f0e10732918a",
    "RepoTags": [
        "latest"
    ],
    "Created": "2021-01-18T15:08:46.767103578Z",
    "DockerVersion": "20.10.2",
    "Labels": null,
    "Architecture": "amd64",
    "Os": "linux",
    "Layers": [
        "sha256:e5d9363303ddee1686b203170d78283404e46a742d4c62ac251aae5acbda8df8",
        "sha256:074cd261bbd4820dd78379e832f14cc4039ff491fece62b1558c7026e27c9ab7",
        "sha256:018d3d4a11d6992f97d169e63ead3d87b75145c19e225e36a4dbf56563fbe60e"
    ],
    "Env": [
        "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    ]
}
[root@lab-podman ~]#
```

Como es una imagen sencilla y que solo tiene una versión no hay mucha información. En una máquina que tenga Skopeo instalado ejecutar lo siguiente para ver los metadatos de la imagen que utilizamos para construir la aplicación web:

```console
$ skopeo inspect docker://docker.io/php:7-apache
```

Podemos utilizar el comando **jq** para, por ejemplo, ver las variables de entorno que utiliza:

```console
[root@lab-podman ~]# skopeo inspect docker://docker.io/php:7-apache | jq '.Env'
[
  "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
  "PHPIZE_DEPS=autoconf \t\tdpkg-dev \t\tfile \t\tg++ \t\tgcc \t\tlibc-dev \t\tmake \t\tpkg-config \t\tre2c",
  "PHP_INI_DIR=/usr/local/etc/php",
  "APACHE_CONFDIR=/etc/apache2",
  "APACHE_ENVVARS=/etc/apache2/envvars",
  "PHP_EXTRA_BUILD_DEPS=apache2-dev",
  "PHP_EXTRA_CONFIGURE_ARGS=--with-apxs2 --disable-cgi",
  "PHP_CFLAGS=-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64",
  "PHP_CPPFLAGS=-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64",
  "PHP_LDFLAGS=-Wl,-O1 -pie",
  "GPG_KEYS=42670A7FE4D0441C8E4632349E4FDC074A4EF02D 5A52880781F755608BF815FC910DEB46F53EA312",
  "PHP_VERSION=7.4.14",
  "PHP_URL=https://www.php.net/distributions/php-7.4.14.tar.xz",
  "PHP_ASC_URL=https://www.php.net/distributions/php-7.4.14.tar.xz.asc",
  "PHP_SHA256=f9f3c37969fcd9006c1dbb1dd76ab53f28c698a1646fa2dde8547c3f45e02886"
]
[root@lab-podman ~]# 
```

Con Skopeo también podemos copiar imagenes entre diferentes registries. Por ejemplo para copiar la imagen anterior al registry corporativo:

```console
$ skopeo copy docker://docker.io/php:7-apache docker://registry.mycompany.com/php:7-apache
```

Si necesitamos autenticarnos, por ejemplo para borrar una imagen:

```console
$ skopeo login docker.io
Username: jadebustos2
Password: 
Login Succeeded!
$ skopeo delete docker://docker.io/jadebustos2/devops
[root@lab-podman ~]# skopeo logout docker.io
Removed login credentials for docker.io
[root@lab-podman ~]# 
```

Con skopeo también podemos clonar repositorios para tener una copia:

```console
$ skopeo sync --src docker --dest docker registry.example.com/busybox registry.mycompany.com
```

+ **--src** y **-dest** indica el transporte para el origen y destino. **docker** indica que es un registry que se encuentra accesible por red. Si tuvieramos las imágenes en un directorio tanto para **--src** como para **--dest** o ambos en lugar de **docker** pondríamos **dir**.
+ **registry.example.com/busybox** indica el registry y la imagen que vamos a replicar, **busybox**.
+ **registry.mycompany.com** indica el registry al cual se sincronizará la imagen.

> ![INFORMATION](../imgs/information-icon.png) [Más información sobre la sincronización de imágenes](https://github.com/containers/skopeo/blob/master/docs/skopeo-sync.1.md)

> ![INFORMATION](../imgs/information-icon.png) [Skopeo](https://github.com/containers/skopeo)