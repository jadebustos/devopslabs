# Desplegando una aplicación TLS

## Gestión de certificados

Para desplegar una aplicación con TLS necesitaremos certificados.

En los siguientes ejemplos vamos a utilizar una autoridad de certificación, CA, que firmará los certificados. En este caso es una autoridad de certificación propia cuyo certificado es autofirmado y por dicho motivo no será reconocida por los navegadores. Esta autoridad de certificación no ofrece garantía alguna ya que no existe una tercera parte de confianza que haya firmado su clave y por tanto certifique que es de confianza. Para los propósitos de este laboratorio es más que suficiente, pero no para un entorno en producción.

Con el fin de evitar el crear certificados se suministran los siguientes ficheros:

+ [server.key](webapp-tls/server.key), clave generada para el servidor.
+ [server.csr](webapp-tls/server.csr), petición de firma del certificado. No se utilizará, pero se incluye con motivos ilustrativos.
+ [server.crt](webapp-tls/server.crt), certificado para el servidor. Se ha utilizado el FQDN **foo-tls.bar**.
+ [cacert.pem](webapp-tls/cacert.pem), certificado, autofirmado, de la autoridad de certificación.

Para generar la clave del servidor y la petición de firma de la clave se ha utilizado el siguiente comando:

```console
[kubeadmin@master ~]$ openssl req -nodes -newkey rsa:4096 -sha512 -keyout server.key -out server.csr -batch -subj "/C=SP/ST=Spain/L=Madrid/O=MyOrganization/OU=MyOrganizationUnit/CN=foo-tls.bar/emailAddress=user@domain"
Generating a RSA private key
...................................................................................................++++
......................................................................................................................................................................................................++++
writing new private key to 'server.key'
-----
[kubeadmin@master ~]$ 
```

Para generar el certificado, firma del CSR, se ha utilizado el siguiente comando:

```console
[kubeadmin@master ~]$ openssl ca -extensions server -name ACMECA -out server.crt -infiles server.csr 
Using configuration from /etc/pki/tls/openssl.cnf
Enter pass phrase for /etc/pki/ACMECA/private/cakey.pem:
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 13 (0xd)
        Validity
            Not Before: Jun 10 13:09:39 2021 GMT
            Not After : Jun 10 13:09:39 2022 GMT
        Subject:
            countryName               = SP
            stateOrProvinceName       = Spain
            organizationName          = MyOrganization
            organizationalUnitName    = MyOrganizationUnit
            commonName                = foo-tls.bar
            emailAddress              = user@domain
        X509v3 extensions:
            Netscape Cert Type: 
                SSL Server
Certificate is to be certified until Jun 10 13:09:39 2022 GMT (365 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated
[kubeadmin@master ~]$
```

Una vez que tenemos el certificado es necesario crear un secret con el certificado y la clave. Creamos el **secret** en kubernetes, incluye la clave y el certificado:

```console
[kubeadmin@master ~]$ kubectl create secret tls foo-tls-secret --key devopslabs/labs-k8s/webapp-tls/server.key --cert devopslabs/labs-k8s/webapp-tls/server.crt --namespace webapp-tls
secret/foo-tls-secret created
[kubeadmin@master ~]$ kubectl get secrets/foo-tls-secret --namespace webapp-tls
NAME             TYPE                DATA   AGE
foo-tls-secret   kubernetes.io/tls   2      87s
[kubeadmin@master ~]$ kubectl describe secrets/foo-tls-secret --namespace webapp-tls
Name:         foo-tls-secret
Namespace:    webapp-tls
Labels:       <none>
Annotations:  <none>

Type:  kubernetes.io/tls

Data
====
tls.crt:  6917 bytes
tls.key:  3272 bytes
[kubeadmin@master ~]$
```

Podemos obtener la definición del secret en formato YAML:

```console
[kubeadmin@master ~]$ kubectl get secret foo-tls-secret --namespace webapp-tls -o yaml
apiVersion: v1
kind: Secret
metadata:
  name: foo-tls-secret
  namespace: webapp-tls
type: kubernetes.io/tls
data:
  tls.crt: Q2VydGlmaWNhdGU6CiAgICBEYXRhOgogICAgIC...
  tls.key: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk....
[kubeadmin@master ~]$
```

El fichero [routed-tls-webapp.yaml](webapp-tls/routed-tls-webapp.yaml) describe un deployment para una aplicación utilizando TLS y con su propio certificado.

> ![IMPORTANT](../imgs/important-icon.png) En este caso el ingress controller realiza la terminación SSL y a partir del ingress controller la comunicación va en plano, no encriptada. Este tráfico no encriptado se realiza dentro de kubernetes. Es posible realizar la comunicación totalmente encriptada hasta el contenedor, será necesario configurar el ingress controller en modo **ssl-passthrough**.

> ![IMPORTANT](../imgs/important-icon.png) Es posible utilizar un único certificado para todas las aplicaciones en kubernetes utilizando wildcards, **\*** y configurando el certificado en el ingress controller en lugar de en el ingress de la aplicación.