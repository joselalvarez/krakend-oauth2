package org.jla.ehr.api.client

import io.micronaut.http.HttpHeaders
import io.micronaut.http.HttpResponse
import io.micronaut.http.annotation.Get
import io.micronaut.http.annotation.Header
import io.micronaut.http.annotation.Headers
import io.micronaut.http.client.annotation.Client
import org.jla.ehr.api.model.Patient

@Client("\${mpi.address}")
@Headers(
    Header(name = HttpHeaders.USER_AGENT, value = "EHR HTTP Client"),
    Header(name = HttpHeaders.ACCEPT, value = "application/json")
)
interface MpiClient {
    @Get("/v1/mpi/patient/{id}")
    fun getPatient(id: String): HttpResponse<Patient>
}