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