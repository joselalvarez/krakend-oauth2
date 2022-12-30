package org.jla.ehr.api.service

import io.micronaut.http.HttpStatus
import jakarta.inject.Singleton
import org.jla.ehr.api.client.MpiClient
import org.jla.ehr.api.model.Ehr
import org.jla.ehr.api.repository.EhrRepository
import org.slf4j.LoggerFactory

@Singleton
class EhrService(private val ehrRepository: EhrRepository, private val mpiClient: MpiClient) {

    private val logger = LoggerFactory.getLogger(EhrService::class.java)

    companion object Exceptions{
        class PatientNotFound(message: String) : Exception(message)
        class MpiResponseError(message: String) : Exception(message)
    }

    fun mergeDocument(patientId: String, document: String): Ehr {
        mpiClient.getPatient(patientId).let {
            if (HttpStatus.OK == it.status) {
                val patient = it.body();
                if (patient != null) {
                    return ehrRepository.merge(Ehr(patient.ehrId, document))
                }
                logger.warn("Patient '$patientId' is null")
                throw Exceptions.PatientNotFound("Patient '$patientId' is null")
            } else if (HttpStatus.NOT_FOUND == it.status) {
                logger.warn("Patient '$patientId' not found")
                throw Exceptions.PatientNotFound("Patient '$patientId' not found")
            } else {
                logger.error("Mpi response error with status: '${it.status}'")
                throw Exceptions.MpiResponseError("Mpi response error with status: '${it.status}'")
            }
        }
    }

    fun getAllDocuments(): List<Ehr> {
        return ehrRepository.findAll()
    }
}