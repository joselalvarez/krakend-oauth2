package org.jla.mpi.api.controller

import io.micronaut.http.HttpHeaders
import io.micronaut.http.HttpResponse
import io.micronaut.http.MediaType
import io.micronaut.http.annotation.Controller
import io.micronaut.http.annotation.Get
import io.micronaut.http.annotation.Produces
import org.jla.mpi.api.model.Patient
import org.jla.mpi.api.service.PatientService
import org.jla.mpi.api.util.JWTUtil
import org.slf4j.LoggerFactory

@Controller("/patient")
class PatientController constructor(private val patientService: PatientService, private val jwtUtil: JWTUtil) {

    private val logger = LoggerFactory.getLogger(PatientController::class.java)

    @Get("/{id}")
    @Produces(MediaType.APPLICATION_JSON)
    fun get(id: String, headers: HttpHeaders): HttpResponse<Patient> {

        if (jwtUtil.tokenIsPresent(headers)){
            logger.info("JWT claims: ${jwtUtil.getTokenFrom(headers)?.jwtClaimsSet?.toString()}");
        }

        var patient = patientService.getPatient(id)
        if (patient != null) {
            logger.info("Patient '$id' found with ehr: '${patient.ehrId}'")
            return HttpResponse.ok(patient)
        }
        logger.warn("Patient '$id' not found!")
        return HttpResponse.notFound()
    }

}