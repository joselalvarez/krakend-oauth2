variable "keycloak_expose_port" {
    type = number
}

variable "mpi_client_secret" {
    type = string
}

job "cluster-keycloak" {

    datacenters = ["dc1"]

    group "keycloak-ingress" {
        network {
            mode = "bridge"
            port "http" {
               static = var.keycloak_expose_port
            }
        }

        service {
            name = "keycloak-ingress"
            port = "http"
            connect {
                gateway {
                    ingress {
                        listener {
                            port = var.keycloak_expose_port
                            protocol = "tcp"
                            service {
                                name = "keycloak"
                            }
                        }
                    }
                }
            }
        }
    }

    group "keycloak" {
        network {
            mode = "bridge"
            port "http" {
                to = 8080
            }
        }

        service {
            name = "keycloak"
            port = 8080
            connect {
                sidecar_service {}
                sidecar_task {
                    resources {
                        cpu    = 50
                        memory = 128
                    }
                }
            }
        }

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
    }


}