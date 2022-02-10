# Recuperando la información del Service Principal

Como comentamos en [Primeros pasos en Azure](00-primeros-pasos-azure) deberemos crear un Service Principal y apuntar los datos. Si se nos olvidará podemos recuperar la información.

Para ello si conocemos el nombre podemos recuperar la información del objeto:

```console
[user@terraform ~]$ az ad sp list --all --display-name azure-cli-2022-02-09-17-22-31
[
  {
    "accountEnabled": "True",
    "addIns": [],
    "alternativeNames": [],
    "appDisplayName": "azure-cli-2022-02-09-17-22-31",
    "appId": "308e57e8-a253-455e-9bf1-6c24f94d8801",
    "appOwnerTenantId": "22c8b4a4-d926-43b2-bcc7-87b998590b47",
    "appRoleAssignmentRequired": false,
    "appRoles": [],
    "applicationTemplateId": null,
    "deletionTimestamp": null,
    "displayName": "azure-cli-2022-02-09-17-22-31",
    "errorUrl": null,
    "homepage": null,
    "informationalUrls": {
      "marketing": null,
      "privacy": null,
      "support": null,
      "termsOfService": null
    },
    "keyCredentials": [],
    "logoutUrl": null,
    "notificationEmailAddresses": [],
    "oauth2Permissions": [
      {
        "adminConsentDescription": "Allow the application to access azure-cli-2022-02-09-17-22-31 on behalf of the signed-in user.",
        "adminConsentDisplayName": "Access azure-cli-2022-02-09-17-22-31",
        "id": "8ba83fc3-2ad2-4042-b420-b6ae90c24b5f",
        "isEnabled": true,
        "type": "User",
        "userConsentDescription": "Allow the application to access azure-cli-2022-02-09-17-22-31 on your behalf.",
        "userConsentDisplayName": "Access azure-cli-2022-02-09-17-22-31",
        "value": "user_impersonation"
      }
    ],
    "objectId": "887c66e2-874f-48cc-bffe-59468260dcb0",
    "objectType": "ServicePrincipal",
    "odata.type": "Microsoft.DirectoryServices.ServicePrincipal",
    "passwordCredentials": [],
    "preferredSingleSignOnMode": null,
    "preferredTokenSigningKeyEndDateTime": null,
    "preferredTokenSigningKeyThumbprint": null,
    "publisherName": "UNIR",
    "replyUrls": [],
    "samlMetadataUrl": null,
    "samlSingleSignOnSettings": null,
    "servicePrincipalNames": [
      "308e57e8-a253-455e-9bf1-6c24f94d8801"
    ],
    "servicePrincipalType": "Application",
    "signInAudience": "AzureADMyOrg",
    "tags": [],
    "tokenEncryptionKeyId": null
  }
]
[user@terraform ~]$
```

Si no conocieramos el display name y no lo hubieramos especificado como será algo similar a **azure-cli-2022-02-09-17-22-31** siempre podemos listar todos los service principal, redirigirlos a un fichero y filtrar por **azure-cli** el contenido del fichero, por ejemplo, y luego buscar los que cumplen el patrón para identificarlos:

```console
[user@terraform ~]$  az ad sp list --all > azure.spn
[user@terraform ~]$
```

Una vez que lo hemos identificado y tenemos el display name podemos ver los datos del objeto, con lo cual buscamos el password:

```console
[user@terraform ~]$ az ad sp list --all --display-name azure-cli-2022-02-09-17-22-31 | grep passwordCredentials
    "passwordCredentials": [],
[user@terraform ~]$
```

El password, como era de esperar, no vamos a poder recuperarlo. 

> ![IMPORTANT](../imgs/important-icon.png) Por motivos de seguridad los passwords no se deben almacenar, ya que si se almacenan, un atacante o un fallo de seguridad puede comprometer todas las cuentas. Por ese motivo se utilizar otros mecanismos basados en hash, por ejemplo, para poder autenticar a un usuario sin almacenar su clave.

Por este motivo lo que vamos a hacer es cambiar la password:

```console
[user@terraform ~]$ az ad sp create-for-rbac --name azure-cli-2022-02-09-17-22-31 --query password -o tsv 
Found an existing application instance of "308e57e8-a253-455e-9bf1-6c24f94d8801". We will patch it
The output includes credentials that you must protect. Be sure that you do not include these credentials in your code or check the credentials into your source control. For more information, see https://aka.ms/azadsp-cli
9lt7kjGv9zdZ3_6rsA870pF-Yt541DrGVT
[user@terraform ~]$
```

Luego el nuevo password para el service principal sería **9lt7kjGv9zdZ3_6rsA870pF-Yt541DrGVT**.

Y para recuperar los otros dos valores que nos hacen falta para configurar las credenciales en terraform:

```console
[user@terraform ~]$ az ad sp list --all --display-name azure-cli-2022-02-09-17-22-31 | grep Tenant
    "appOwnerTenantId": "22c8b4a4-d926-43b2-bcc7-87b998590b47",
[user@terraform ~]$ az ad sp list --all --display-name azure-cli-2022-02-09-17-22-31 | grep appId
    "appId": "308e57e8-a253-455e-9bf1-6c24f94d8801",
[user@terraform ~]$
```

