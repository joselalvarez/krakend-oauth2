package org.jla.ehr.api.controller

import io.micronaut.http.HttpResponse
import io.micronaut.http.MediaType
import io.micronaut.http.annotation.Body
import io.micronaut.http.annotation.Controller
import io.micronaut.http.annotation.Get
import io.micronaut.http.annotation.Post
import io.micronaut.http.annotation.Produces
import org.jla.ehr.api.model.Ehr
import org.jla.ehr.api.service.EhrService

@Controller("/ehr")
class EhrController(private val ehrService: EhrService) {

    @Post(value = "/{patientId}", consumes = [MediaType.TEXT_PLAIN])
    @Produces(MediaType.APPLICATION_JSON)
    fun merge(patientId: String, @Body body: String): HttpResponse<Ehr>{
        return try {
            HttpResponse.ok(ehrService.mergeDocument(patientId, body))
        }catch(e1: EhrService.Exceptions.PatientNotFound){
            HttpResponse.badRequest()
        }catch(e: Exception){
            HttpResponse.serverError()
        }
    }

    @Get()
    @Produces(MediaType.APPLICATION_JSON)
    fun getAll(): HttpResponse<List<Ehr>> {
        return HttpResponse.ok(ehrService.getAllDocuments())
    }
}