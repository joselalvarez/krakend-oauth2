# Autorización OAuth2 usando el API gateway KrakenD
El siguiente proyecto es un ejemplo de como se puede usar el *API gateway* [KrakenD](https://www.krakend.io/) en combinación con la *service mesh* del cluster para desacoplar todas las tareas relativas a la autorización de los microservicios.

*KrakenD* es un *API gateway* con un escaso consumo de recursos, no necesita base de datos y puede ser configurada totalmente "as code", además es fácilmente escalable. Por todos estos motivos, es ideal para ser desplegada dentro del cluster como si fuera un sidecar más del microservicio, permitiendo delegar en ella toda la lógica de la autorización.

El diagrama del cluster es el siguiente:

![Cluster](https://github.com/joselalvarez/krakend-oauth2/blob/main/_imgs/cluster.png?raw=true)

Por un lado tenemos un microservicio "MPI" (Master Patient Index) que hace la función de recurso a proteger. Este servicio retorna datos de pacientes a aquellos clientes que presenten un token de acceso válido con el correspondiente *scope* "mpi/patient.get". En este caso *KrakenD* es la puerta de entrada del servicio (Ingress gateway) y se encarga de validar el token para las peticiones entrantes, para ello hace uso de los certificados publicados por el [Keycloak](https://www.keycloak.org/) en el endpoint JWK. Las comunicaciones entre el servicio MPI, *KrakenD* y el *Keycloak* se realizan de forma segura dentro de la *service mesh*.

Por otro lado tenemos el microservicio "EHR" (Electronic Health Record) que hace la función de cliente o consumidor de datos de paciente. En este caso *KrakenD* es la puerta de salida del servicio (Terminating gateway) y se encarga de solicitar un token de acceso al *Keycloak* e inyectarlo a las peticiones salientes que viajan hacia el MPI. Las comunicaciones entre el servicio EHR y *KrakenD* se realizan de forma segura dentro de la *service mesh*.

## Requisitos previos de instalación
La distribución de Linux y las versiones de los componentes son solo a modo de orientación:
- [Rocky Linux 9](https://rockylinux.org) (distribución RHEL 9 compatible)
- [Docker](https://docs.docker.com/get-docker) 20.10.21
- [HashiCorp Nomad](https://www.nomadproject.io) 1.4.3
- [HashiCorp Consul](https://www.consul.io) 1.14.2
- [HashiCorp Terraform](https://www.terraform.io) 1.3.6
- [Sdkman](https://sdkman.io) 5.16.0
- [OpenJDK 11 GraalVM](https://www.graalvm.org) 22.1.0.r11-grl
- [Maven](https://maven.apache.org) 3.8.6
- [Micronaut](https://micronaut.io) 3.7.4

### Instalación de Docker, Nomad, Consul y Terraform
En el siguiente [enlace](https://github.com/joselalvarez/nomad-sample-cluster) se puede encontrar la información necesaria para realizar la instalación y ejecución de un cluster Nomad.

### Instalación de sdkman
Ejecutar el siguiente comando y seguir las instrucciones (Opciones por defecto).
```
$ curl -s https://get.sdkman.io | bash
```

Tras finalizar la instalación hay que abrir una nueva terminal de la consola o forzar la recarga de las variables de entorno. Para verificar la instalación:
```
$ sdk v
```

### Instalación de la OpenJDK 11 GraalVM y la imagen nativa
Instalar la OpenJDK 11 específica para GraalVM con *sdkman*:
```
$ sdk install java 22.1.0.r11-grl
```

Verificar la instalación:
```
$ java --version
$ gu --version
```

A continuación instalar la imagen nativa:
```
$ gu install native-image
```

### Instalación de Maven
```
$ sdk install maven
```

### Instalación de Micronaut
```
$ sdk install micronaut
```

### Construcción e instalación de las imágenes docker de los microservicios
La construcción de las imágenes se realiza mediante Maven con la opción de empaquetado "docker-native":
```
$ cd mpi
$ mvn package -Dpackaging=docker-native -Djib.to.tags=0.1
....

$ cd ../ehr
$ mvn package -Dpackaging=docker-native -Djib.to.tags=0.1
....


```
Tras finalizar el proceso las imágenes aparecerán instaladas en nuestro repositorio local, listas para ser usadas por *Nomad*:
```
$ docker image list
REPOSITORY                             TAG                 IMAGE ID       CREATED         SIZE
ehr                                    0.1                 c3e061220640   25 hours ago    80.5MB
mpi                                    0.1                 c5e0b6516817   25 hours ago    85.7MB
....
```

## Despliegue y ejecución del cluster
Para desplegar el cluster ir a la carpeta de los descriptores y ejecutar *Terraform*:
```
$ cd cluster
$ terraform init
$ terraform apply
```

Para probar la correcta ejecución de todo el proceso de autorización podemos realizar la siguiente petición al servicio EHR:
```
$ curl -d "Prueba de documento 1" -H "Content-Type:text" -X POST http://localhost:8082/erh/00000000T
{"ehrId":"0a5a3eae-de04-4a3e-9dc0-975509d64bbf","document":"Prueba de documento 1"}

```
La ejecución guarda el documento "Prueba de documento 1" con el "ehrId" correspondiente a el paciente "00000000T" que ha retornado el servicio MPI.

Si vamos a la consola del contenedor donde se ejecuta el MPI podemos ver los logs de la petición final:
```
$ [io-executor-thread-4] INFO  o.j.m.a.controller.PatientController - JWT claims: {"sub":"633c289a-a86d-4388-86d3-a30bc8fb19d8","acr":"1","clientHost":"127.0.0.1","clientId":"mpi-client","azp":"mpi-client","scope":"mpi/patient.get","iss":"http://10.0.2.15:8080/auth/realms/ClusterRealm","typ":"Bearer","exp":1672327824,"iat":1672327524,"clientAddress":"127.0.0.1","jti":"b812267e-361d-4325-9904-a02cb7d7303c"}
$ [io-executor-thread-4] INFO  o.j.m.a.controller.PatientController - Patient '00000000T' found with ehr: '0a5a3eae-de04-4a3e-9dc0-975509d64bbf'

```
Nota: Por defecto *KrakenD* elimina todas las cabeceras de la petición original al reenviarla al backend. En este caso, se ha configurado para que permita el paso del token, en ocasiones el token no solo es necesario para autorizar, si no que contiene información extra que puede ser utilizada por el servicio.

También podemos comprobar que el *Ingress gateway* esta validando los tokens de acceso: 

```
$ curl -I -X GET http://localhost:8081/v1/mpi/patient/00000000T
HTTP/1.1 401 Unauthorized

```

Para detener el cluster y borrar el historial de ejecuciones:
```
$ terraform destroy
$ nomad system gc
```

## Configuración del *Keycloak*
Dentro de los descriptores del cluster hay un fichero llamado "keycloak-realm.json.tpl" con la configuración "as code" del *Keycloak*. A continuación se indica el proceso de como obtenerlo en el caso de que alguien esté interesado.

### Arrancar un contenedor del *Keycloak*
```
$ docker run -p 8080:8080 -e KEYCLOAK_USER=admin -e KEYCLOAK_PASSWORD=password jboss/keycloak:16.1.1
```

Tras el arranque del contenedor, la consola de administración tiene que estar accesible en la url "http://localhost:8080/auth/admin" y deberíamos poder logearnos con las credenciales indicadas en el arranque del contenedor. 

### Crear un nuevo *Realm*

En la esquina superior izquierda, al pasar el ratón sobre el desplegable podemos encontrar la opción para añadir un nuevo *realm* 

![Keycloak add realm](https://github.com/joselalvarez/krakend-oauth2/blob/main/_imgs/keycloak-1.png?raw=true)

Le damos un nombre y lo creamos.

![Keycloak name](https://github.com/joselalvarez/krakend-oauth2/blob/main/_imgs/keycloak-2.png?raw=true)

### Crear el *Client Scope*
Seleccionamos la opción *Client Scope* -> *Create*

![Keycloak scope](https://github.com/joselalvarez/krakend-oauth2/blob/main/_imgs/keycloak-3.png?raw=true)

Le damos un nombre y lo guardamos.

![Keycloak save scope](https://github.com/joselalvarez/krakend-oauth2/blob/main/_imgs/keycloak-4.png?raw=true)

### Crear el *Client*

Seleccionamos la opción *Client* -> *Create*

![Keycloak client](https://github.com/joselalvarez/krakend-oauth2/blob/main/_imgs/keycloak-5.png?raw=true)

Le damos un identificador y lo guardamos.

![Keycloak save client](https://github.com/joselalvarez/krakend-oauth2/blob/main/_imgs/keycloak-6.png?raw=true)

A continuación, definimos el tipo de acceso como "confidential", habilitamos el *grant type -> client_credentials* (Service Accounts Enabled -> ON), añadimos las urls de redirección validas (un asterisco para permitirlas todas) y por último guardamos los cambios.

![Keycloak config client 1](https://github.com/joselalvarez/krakend-oauth2/blob/main/_imgs/keycloak-7.png?raw=true)

![Keycloak config client 2](https://github.com/joselalvarez/krakend-oauth2/blob/main/_imgs/keycloak-8.png?raw=true)

Tras guardar, aparece la pestaña con las credenciales donde podremos ver el *Client Secret* que usaremos para solicitar el token de acceso.

![Keycloak config client 3](https://github.com/joselalvarez/krakend-oauth2/blob/main/_imgs/keycloak-9.png?raw=true)

En la pestaña *Client Scopes* añadimos el *scope* que hemos creado anteriormente. En mi caso, he borrado todos los que había y he dejado solo el nuestro.

![Keycloak config client 4](https://github.com/joselalvarez/krakend-oauth2/blob/main/_imgs/keycloak-10.png?raw=true)

### Solicitar un token de acceso
Si hemos realizado todo el proceso de configuración correctamente, deberíamos poder solicitar un token de acceso:
```
$ curl -d "grant_type=client_credentials&client_id=mpi-client&client_secret=U0YddmDiIMVcQC7wlZNF6Lv0PLLbSgYK" -H "Content-Type: application/x-www-form-urlencoded" -X POST http://localhost:8080/auth/realms/ClusterRealm/protocol/openid-connect/token

{"access_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI2SGoxWFBtVXhhaHA2YXg1NEtUMGJQQ3YxYzdBLWtrdFFBQlBQTkZHNUFNIn0.eyJleHAiOjE2NzIzMzc5ODQsImlhdCI6MTY3MjMzNzY4NCwianRpIjoiYzI2M2YzM2QtNzJjZS00YmQ2LTkyNTAtZTA0ZDZmY2E2ZWRiIiwiaXNzIjoiaHR0cDovL2xvY2FsaG9zdDo4MDgwL2F1dGgvcmVhbG1zL0NsdXN0ZXJSZWFsbSIsInN1YiI6ImQwMzVmYWU3LTMyM2MtNDk0OS05ZGNmLTdmNWZkM2MwY2VmZiIsInR5cCI6IkJlYXJlciIsImF6cCI6Im1waS1jbGllbnQiLCJhY3IiOiIxIiwic2NvcGUiOiJtcGkvcGF0aWVudC5nZXQiLCJjbGllbnRIb3N0IjoiMTcyLjE3LjAuMSIsImNsaWVudElkIjoibXBpLWNsaWVudCIsImNsaWVudEFkZHJlc3MiOiIxNzIuMTcuMC4xIn0.UhM7rXZ3TJ0fcpWF1a5wpeq3uwbIck8x3ImQ5OIfNWXBBKq9e7_eh_yFShrOxep5VfVOujVKJb9bHNXERKTO1ilpjS-gqiBz5FcnvEuTplKr7CETjtCUzIRPHzJ4Y91woWJ33Z7qpBzU1i0axpF8-t-d4Bucmt5OR1iAsbAZjom5pwtYFkNmFsP3dSK_7gat-B5xvRBYESgOWlRiuooiqtyKkEi7Vc_KSL89AiL0LMjsBWIvkIDx-NHdOl2o11SBwTGPY8CQkIHlzRGnkjGpPLGos7k6tldPWoNfwUBzCfDrMszGvTROXRqDa3ppaUN37eGiqPCvMVNNFBqK2BgNjg","expires_in":300,"refresh_expires_in":0,"token_type":"Bearer","not-before-policy":0,"scope":"mpi/patient.get"}

```

### Exportar la configuración
Toda esta configuración que hemos realizado se perderá en el momento que eliminemos el contenedor. Por ello. la idea es exportarla a un fichero JSON y configurar la creación de los contenedores *Keycloak* para que la importen de forma automática. Para exportar la configuración iremos a la opción de menu *Export* y habilitaremos todas las opciones de exportación.

![Keycloak export](https://github.com/joselalvarez/krakend-oauth2/blob/main/_imgs/keycloak-11.png?raw=true)

El fichero resultante contiene el *Realm* con los clientes y los *scopes* que hayamos configurado. En el caso de los *secrets* aparecerán en su lugar una cadena de asteriscos:

```
....
    {
      "id": "820170bb-2f97-46cc-ade0-838de3d0f9b0",
      "clientId": "mpi-client",
      "surrogateAuthRequired": false,
      "enabled": true,
      "alwaysDisplayInConsole": false,
      "clientAuthenticatorType": "client-secret",
      "secret": "**********",
      "redirectUris": [
        "*"
      ],
....
``` 

Esto hay que cambiarlo, en este cluster se usa una variable *Nomad* que es inyectada con *Terraform*:

```
....
    {
      "id": "e60258e8-8cd6-4493-8867-34db2f6cbd94",
      "clientId": "mpi-client",
      "surrogateAuthRequired": false,
      "enabled": true,
      "alwaysDisplayInConsole": false,
      "clientAuthenticatorType": "client-secret",
      "secret": "{{ env "MPI_CLIENT_SECRET" }}",
      "redirectUris": [
        "*"
      ],
....
```

### Configurar el contenedor docker
En el descriptor "cluster-keycloak.nomad.hcl" se puede ver un ejemplo completo de como configurar el contenedor *Keycloak* usando el fichero JSON para importar la configuración. El *Keycloak* necesita una base de datos, en este caso al ser simplemente una prueba de concepto se usa la base de datos H2 embebida y sin volumen de datos.

```
....
        task "app" {
            driver = "docker"

            env {
                MPI_CLIENT_SECRET = var.mpi_client_secret
                KEYCLOAK_USER = "admin"
                KEYCLOAK_PASSWORD = "password"
                KEYCLOAK_IMPORT = "/tmp/keycloak-realm.json"
            }

            template {
                data = file("./keycloak-realm.json.tpl")
                destination = "keycloak-realm.json"
            }

            config {
                image = "jboss/keycloak:16.1.1"
                ports = ["http"]
                volumes = ["keycloak-realm.json:/tmp/keycloak-realm.json"]
            }

            resources {
                cpu    = 500
                memory = 1024
            }
        }
....
```

## Configuración de KrakenD para la puerta de entrada
Los ficheros de configuración de *KrakenD* se pueden realizar mediante la herramienta disponible en su web "https://designer.krakend.io". Mi consejo es realizar la configuración base con esa aplicación, para posteriormente descargar el fichero, editarlo y completarlo  manualmente con los valores definitivos. La plantilla "krakend.json.tpl" contiene la configuración:

```
{
  "$schema": "https://www.krakend.io/schema/v3.json",
  "version": 3,
  "extra_config": {
    "telemetry/logging": {
      "level": "DEBUG",
      "prefix": "[KRAKEND]",
      "syslog": false,
      "stdout": true
    }
  },
  "name": "KrakenD - API Gateway",
  "timeout": "3000ms",
  "cache_ttl": "300s",
  "endpoints": [
    {
      "endpoint": "/v1/mpi/patient/{id}",
      "method": "GET",
      "output_encoding": "no-op",
      "backend": [
        {
          "url_pattern": "/patient/{id}",
          "encoding": "no-op",
          "sd": "static",
          "method": "GET",
          "host": [
            "{{ env "NOMAD_UPSTREAM_ADDR_mpi" }}"
          ]
        }
      ],
      "input_headers": [
        "Authorization"
      ],
      "extra_config": {
        "auth/validator": {
          "alg": "RS256",
          "jwk_url": "http://{{ env "NOMAD_UPSTREAM_ADDR_keycloak" }}/auth/realms/ClusterRealm/protocol/openid-connect/certs",
          "scopes_matcher": "all",
          "scopes": [
            "mpi/patient.get"
          ],
          "disable_jwk_security": true,
          "scopes_key": "scope",
          "cache": true
        }
      }
    }
  ]
}

```
Principales claves:
- "input_headers": Indica el listado de las cabeceras de la petición original que se pasan al backend. En este caso permitimos que la cabecera con el token pase a el servicio y poder acceder a los *claims*.
- "jwk_url: Es la url donde el *Keycloak* publica los certificados que validan la firma del token.
- "scopes": Lista con los *scopes* que debe tener el token de acceso para ser considerado válido (a parte de que la firma sea correcta).
- "scope_matcher": Puede tomar dos valores "all" o "any", es decir, para que el token sea válido debe tener o todos los *scopes* o al menos uno, en función de la opción seleccionada.
- "disable_jwk_security": Deshabilita la seguridad para permitir comunicaciones con el *Keycloak* que no sean *https*. En este caso al estar el *Keycloak* y *KrakenD* dentro de la *service mesh* no aplica. El cifrado de las comunicaciones dentro de la *service mesh* es transparente a los servicios.
- "scopes_key": Es el *path* dentro del token de acceso donde se encuentran los *scopes*.
- "cache": Si la opción está activada, los certificados del *Keycloak* se cachean (15 minutos por defecto), si se desactiva, se realiza una nueva petición para descargarlos cada vez que se tenga que validar un token.


## Configuración de KrakenD para la puerta de salida
La plantilla "krakend-terminating.json.tpl" contiene la configuración:

```
{
  "$schema": "https://www.krakend.io/schema/v3.json",
  "version": 3,
  "extra_config": {
    "telemetry/logging": {
      "level": "DEBUG",
      "prefix": "[KRAKEND]",
      "syslog": false,
      "stdout": true
    }
  },
  "name": "KrakenD - API Gateway",
  "timeout": "3000ms",
  "cache_ttl": "300s",
  "endpoints": [
    {
      "endpoint": "/v1/mpi/patient/{id}",
      "method": "GET",
      "output_encoding": "no-op",
      "backend": [
        {
          "url_pattern": "/v1/mpi/patient/{id}",
          "encoding": "no-op",
          "sd": "static",
          "method": "GET",
          "host": [
            "{{with service "mpi-api-ingress"}}{{with index . 0}}{{.Address}}:{{.Port}}{{end}}{{end}}"
          ],
          "extra_config": {
            "auth/client-credentials": {
              "endpoint_params": {},
              "client_id": "mpi-client",
              "client_secret": "{{ env "MPI_CLIENT_SECRET" }}",
              "token_url": "http://{{with service "keycloak-ingress"}}{{with index . 0}}{{.Address}}:{{.Port}}{{end}}{{end}}/auth/realms/ClusterRealm/protocol/openid-connect/token",
              "scopes": "mpi/patient.get"
            }
          }
        }
      ]
    }
  ]
}
```

Principales claves:
- "output_encoding" y "encoding": Indica el tipo de procesamiento que realiza el *KrakenD* a la petición (json, string, no_op), en este caso se deshabilita el procesamiento para conservar los status de error 4xx. Si se habilita, una respuesta del backend 401 se trasformará en un error 500, que no es lo que deseamos en este caso.
- "client_id": El identificador del cliente configurado en el *Keycloak*
- "client_secret": El *secret* de las credenciales del cliente.
- "token_url": La url donde el *Keycloak* publica los tokens de acceso.
- "scopes": Lista de los *scopes* (separados con espacios) que solicita el cliente con el token de acceso.



