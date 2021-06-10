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

> ![TIP](../imgs/tip-icon.png) El contenido de los ficheros [server.crt](webapp-tls/server.crt) y [server.key](webapp-tls/server.key) no se corresponde con los valores de **tls.crt** y **tls.key** del fichero [routed-tls-webapp.yaml](webapp-tls/routed-tls-webapp.yaml). Esto es debido a que es necesario codificar esos datos en base64. Para obtenerlos en base64:
> ```console
> [kubeadmin@master webapp-tls]$ cat server.key | base64 -w0
>LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUpRZ0lCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQ1N3d2dna29BZ0VBQW9JQ0FRQzFubHpvM1hJelNTWWYKSU9OQnhqU1VNQlRvQzY3Z1pRY29HUEJEWldhbE5rd1ZOME5TYUsxWGRiRWs3ZVhMYU5HaUtpZ1MzSTlBa0VQcwpHY1VGUHM2SDVxcTQxb3M0K2M1YU9hclhLcUVSNnpPc2JGbTVRc1lzaWlOV0N1UkRuQnE5WkdPbytOUmtuS0JsCmdzdTBLS2tsZ0pZMzg0ZHFpMGRPQkJZZk43YXNhaTdzNDB4UDNlZlo2WmorN2x6dG9BV3BIL0ZJd0kvSzIrWWQKZlo5aGkzKzBIZUJhYzNtQi84UUxHVkVGTlBIQ3BGZDV0SXpBbkR2OEdqRS9tYXFpbHQzZlhQTlNmcEVQWDlvSQppZ1g0TnVMME01WDBYRUphSElsVVFFaHo0YnNROGY5K2p3RmZjVWxWU0J6dDFuNVl0UDA3ZXBEZEJyencxS2swCkMybnpEa051bm0wRlAxTVRkK0lPdkNPdjlZdXRmaURNMVdKVVM0anNjWWExVFRKWU82MDNzQ05yNFdLdFdxTVkKQ3pmVDAwOFNJR2IxMzNTTjk3aHNsazRCSTZLdDJRWmpXTHlXZzFKTGg2aWlXOWdHRkhuaXZnYWgwdDB3MFZmTwptbU9QQUkwODIxQkIvVllJc3ppMGlRSFdaR0JrUVZEMzhadGVCMTlVUE83a0oxK2x6aUdLMDdTZWFlSDQ1SFQrCmZRQ3BJdGsxS05rL3NtaTFGLzNaRkZqNmYyMXhHVEJQRGVCZ1d0cFVYMDZSTElUV0Q2S3cwQ1FFSFllTnA2WmoKWlBpMys2Q1JZUHdZb1N0bm93a1lmRkxXYXMrUThreEFqdi9qYnY0NXc1ZWtxTWNTTzBqeFdra0tuY3AwWW0vZwpnZU9pOVB6TUlnQ1J6Mk9MaUx0bU1pajhQaDNYRXdJREFRQUJBb0lDQUF2bG5NWndReHZTN2RsYUtTalUxL3JoCkQyMkgzbU82bW5abzg4d21aMHZwTzZDa0p4Zk4zWlQrRTZXTW8rSG9NdHRCa2JCeW5EdXBkNW1Pc3BZK1gvOE4KQUIvdGhkOHNsZlRaRkRUV0NRa0lkREVXUStaYjFtbHlmeEFTMUpNTk5iODBSVWI3VGNadGNDQldLZ3ZhSWdKZgo0dmMxVDZpT0NSUzJOZEREc0lhb3lmd2dnNDR6eGcxRFBROXVBODVaRGlYZS9zbzZPdkVaNklBRUM1MnpLcUZjCjE2WjFLLzkxQnAySGdnUXFUSy9vWGdhTjZpNXZ6WW9kR1I3R2JTUUxaK3RLeG5HZjh0YWorNzlWYzBDb0w4TzUKWVZoSmR0czZSVkNzaVZKMTlmQU5PaVJMTDliVnIrMFROVG5yTkFtUmlZa001VkpsTDVsREJQWnd6UGJyOTBTNgpWeXhSMjJra2JFWDd3c1N2OCtjV1BKTFJmNm9TT05IQzg4YVdYREtyQUtRUCt1U0FLWFluTG03U2ZTWVhSWndTClNUWXA4ZENiMTFnZXRFL2N3N0pKOWlNTnU1YTFpeU13VHhpMHAxYi94RWREdDNONXlkYUUyN1lSOEY0M2xmeC8KbkhIbzBJQ25ucDZCamNGK1RORXlxZVNnMEN2Q2RVcUx2cUdPMjBnZ1JPckNadDRPTDB2NU5ycm1MSmNWOFhQeQpyZUo2cHE0blZOVzNhR1RzZHZhTVh4Vm5TTHYvREY5MU9scTJzenh3Yzk1czhXNUs1Y290ck1PWWtGQzh0c2dnCldscWIrbkdqcWpyUHhiOHFZM1kwd2x5bFVhUTBWS3ozdmxQNCtQV0xId3FKUEZpaUdmVW91aUZ1RHFXVmV1akIKZkRpWHlTbFV5MklETnZRSG9CUmhBb0lCQVFEd2NOZEtwSTNWcjdXelpjS1ZSb01rb0RZRktEWGdwSmlFbjRoTgpQcXNHZUJpZWsvdVVZMklXbVBnNjNXUjFGWVpyb2hkL0IrMDhGbHA0VUN4MXdCODgyTmxEaHNLeTlZOFV2N3d0CmJRMXRJN0lhaXNvcFZzcm1Hb1RiMU1POFc3KzRLQzhlMm8vbFJmWDdtV05GVEcySXhtbmtIbDU1QTNMVVF3T3gKOTd2Q0FVd25WNjlaMjQ4V1V3b0VnNjZRZXdZWDdDTzZzZkpkU1QzWFdLTTNEdFpsdGZuQ3IvVm14TDRVUFFjWApJQmdsY1B1QS8reWVzVzFUVUF6b3pIV1NFcnR6WHkyVThYUlFCMUtlejBmNm9IRHVzK0pCZzJZU0tiOXBWWlFoClh1ODFWR24zbWxEOXYvY1BHNnAySGd5Tis1d1NoV3M1VlViOFdiWkFxNWtSSE5KeEFvSUJBUURCWHhIT3habUEKUGNYY1JYR29DQ2padXpROHliejhWejFXcUhodEYxVzNQeE4yaFJmN2l0Qml0dzZHZUpNQXZWOGJqc0Z5SXVQSApuelh6L0NDV0R2ck5oeHNPVUhUZk9FSGc2ZWw1MlgxeW13RGZxMXVOeHdWVlQ1bHUrNDJyV0M5WGRRY0w1YlZECmxmTVQ3QTM3ZFkwMENKbDF2S2FxdlozMmhuZ3hZQnAreTY5YjBvOTRMbHQyalF3WE13VUpBTjNIcGdTOUpWUjQKR09lTmYzVGVXY1g1VkM2aFdWNUR5azBtREZyYUVBNWdmRkNwWDJsWnZZMnFzQkZhSU5vTi9QQ0VHR3NPeVpFcAozbUg3Uyt4by9hZWFtK3dSSHlKczhCSGFOZXFsREVYWDhhL2I2OXNOVDZXbnoyYkJER1JkRTRwUjJsR1VsRitCCk1CWENVcTBsQWJ2REFvSUJBR2N3SmxWVWRjS0ZYRGVYcm9DZCtGNVptNVZ2QW1CY2cxQTNueWwzZ2JLUERCSFMKZEova1h3NVByQWluUnh1d2x6WE9KTU5SeFpDS0QxMmZHdFdXRkZIcXhxTmlUR0M5WGlDTGdOa0Yra01pbEtjcgpkVU4waWpOaW9pNHVDNnJrdlV6dGdmdDkxVStTVE5VanFTVHVmZnU3RzJyWlZiWWRzc1JCMW00a1lhSUxLSUdoCjhoRmdWdkkveFFiVzlLM3cvbFo1ODRPR0p2dStHUm80WWlPWTdJNU9JTmhhNTdpcEt1SklwcWhZRDhUUnpqNDQKbDNZcnN6MlVGMVk1bVNPTmdvRXJFY2JnTVFpL2U4ZklNWjN3Q1VlSVQ4dko5cDVJNkdydVhWcE5BZUFqVUM4QgpQVTBKZTZBeVFWL2IyWXQ5dGllRXR0V3VNWDdQaVpZTGp1OTNMU0VDZ2dFQVFKc0swQktrM252RkIzc01KaC9UCnhpc05vT0dtQ29qN0xXRE1HMmFZZE1qV0w5cjMwRXJvcEpLVWY4ajVGRjR3MEh3NWxYQ2l1YWN2MTN4OVJxVnEKbGhCMXNhcWY0WlJpTGtyNGZvVnpyRDZ0WkExVVlXSUZIaU9pRjdwajhzTmJ6ZFNEcmkzcENkT25peGhxODRDcQoxSitxNWZOSm0vSU9QTGRnb042Qys2b0J4S1BzMnpKaHpKSURZQnpqcWNab1VyUGRFWFRQYS9DbUxGaFJLNWpDCjFES1VBY1JpQWpRczRuRnVTVHprRU1oNENwNmVEQ1dRbDE2TDdaamNRYUFvbTNtdEN4dTlMRWZvWkpWUlB5TEEKUkoramwzVFhnNTRSMk4zNnIzb1NPN3U4RGJZWFViTXluWVpseGtubG5sTlErMWY5dWE1NDJpaStuRllURXpJcApFUUtDQVFFQW1XNWU4ZXNJYkhUdTk4SXl1ekRUU1hENGJLNE9ZOG1wdFZhUHFRaDNPaEpyR2lqaFEvOXZCVFNGCkNoWmFqNlFybURGMDBKMXhJSkgydHZXcHNFL2paaFlyVTF2LzAwcG9WcEVObFFuWlFZWXhwKzhXeUxIWXg4clYKdklxeUxIbG5WUHhhd3BTU2dScVFXMUdXYmtzMTlNWmJVeG95QXlUQVNjcjN5UGxrVXhUWUJIcmVPTVJLSXNsSgozbDAxT3lVVFRXWGhSemlZTHVsaWJoY0x0QjdJcCszUmh5bUNHcUwrbGpLcFQ0UkRtd0tHY3FKQkEzdmxFWDFzCjhoMTZxaXdHNGZvWDNTWDhvcEliWFlvd3hzSmJTTzBpaDZLSDl4MFlSekxsa01SdDFFSlBNdHM1RHB4MkxxVWkKdUc4cnFEZ3FPb05ieFNDUTlGQTlLaEZocTJUaldnPT0KLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLQo=[kubeadmin@master webapp-tls]$
> ```

> ![IMPORTANT](../imgs/important-icon.png) En este caso el ingress controller realiza la terminación SSL y a partir del ingress controller la comunicación va en plano, no encriptada. Este tráfico no encriptado se realiza dentro de kubernetes. Es posible realizar la comunicación totalmente encriptada hasta el contenedor, será necesario configurar el ingress controller en modo **ssl-passthrough**.

> ![IMPORTANT](../imgs/important-icon.png) Es posible utilizar un único certificado para todas las aplicaciones en kubernetes utilizando wildcards, **\***, y configurando el certificado en el ingress controller en lugar de en el ingress de la aplicación.

> ![IMPORTANT](../imgs/important-icon.png) Por defecto los datos secretos se almacenan en **etcd** en claro. Esto es un riesgo de seguridad. Es posible aumentar la seguridad activando [Encryption at rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/).