provider "nomad" {
    address = "http://10.0.2.15:4646"
}

variable "keycloak_expose_port" {
    type = number
    default = 8080
}

variable "mpi_client_secret" {
    type = string
    default = "vMTTyeSaglI1TaYtqkq1b5uxXjRKGSok"
}

variable "mpi_expose_port" {
    type = number
    default = 8081
}

variable "ehr_expose_port" {
    type = number
    default = 8082
}

resource "nomad_job" "cluster-keycloak" {
    jobspec = file("cluster-keycloak.nomad.hcl")
    hcl2 {
        enabled  = true
        allow_fs = true
        vars = {
            "keycloak_expose_port" = var.keycloak_expose_port
            "mpi_client_secret" = var.mpi_client_secret
        }
    }
}

resource "nomad_job" "cluster-mpi" {
    jobspec = file("cluster-mpi.nomad.hcl")
    hcl2 {
        enabled  = true
        allow_fs = true
        vars = {
            "mpi_expose_port" = var.mpi_expose_port
        }
    }
}

resource "nomad_job" "cluster-mpi-client" {
    jobspec = file("cluster-mpi-client.nomad.hcl")
    hcl2 {
        enabled  = true
        allow_fs = true
        vars = {
            "mpi_client_secret" = var.mpi_client_secret
            "ehr_expose_port" = var.ehr_expose_port
        }
    }
}