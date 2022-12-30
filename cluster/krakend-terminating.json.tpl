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