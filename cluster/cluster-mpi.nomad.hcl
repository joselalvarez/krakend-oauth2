variable "mpi_expose_port" {
    type = string
}

job "cluster-mpi" {

    datacenters = ["dc1"]

    group "mpi-api-ingress" {
        network {
            mode = "bridge"
            port "http" {
              static = var.mpi_expose_port
            }
        }

        service {
            name = "mpi-api-ingress"
            port = "http"
            connect {
                gateway {
                    ingress {
                        listener {
                            port = var.mpi_expose_port
                            protocol = "tcp"
                            service {
                                name = "mpi-api"
                            }
                        }
                    }
                }
            }
        }
    }

    group "mpi-api" {
        network {
            mode = "bridge"
            port "http" {
                to = 8080
            }
        }

        service {
            name = "mpi-api"
            port = 8080
            connect {
                sidecar_service {
                    proxy {
                        upstreams {
                            destination_name = "keycloak"
                            local_bind_port  = 8000
                        }
                        upstreams {
                            destination_name = "mpi"
                            local_bind_port  = 8001
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

            template {
                data = file("./krakend.json.tpl")
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

    group "mpi" {

        network {
            mode = "bridge"
            port "http" {
                to = 8001
            }
        }

        service {
            name = "mpi"
            port = 8001

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

            config {
                image = "mpi:0.1"
                ports = ["http"]
            }

            resources {
                cpu    = 100
                memory = 128
            }
        }

    }


}