
variable "mpi_client_secret" {
    type = string
}

variable "ehr_expose_port" {
    type = number
}

job "cluster-mpi-client" {

    datacenters = ["dc1"]

        group "mpi-client" {

        network {
            mode = "bridge"
            port "http" {
                to = 8002
                static = var.ehr_expose_port
            }
        }

        service {
            name = "mpi-client"
            port = 8002

            connect {
                sidecar_service {
                     proxy {
                        upstreams {
                            destination_name = "mpi-api-terminating"
                            local_bind_port  = 8082
                        }
                    }
                }
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
                MPI_ADDRESS = "http://${NOMAD_UPSTREAM_ADDR_mpi-api-terminating}"
            }

            config {
                image = "ehr:0.1"
                ports = ["http"]
            }

            resources {
                cpu    = 100
                memory = 128
            }
        }

    }

    group "mpi-api-terminating" {
        network {
            mode = "bridge"
            port "http" {
                to = 8080
            }
        }

        service {
            name = "mpi-api-terminating"
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
            }
            
            template {
                data = file("./krakend-terminating.json.tpl")
                destination = "krakend.json"
            }

            config {
                image = "devopsfaith/krakend:2.1.3"
                ports = ["http"]
                volumes = ["krakend.json:/etc/krakend/krakend.json"]
            }

            resources {
                cpu    = 100
                memory = 256
            }
        }
    }

}