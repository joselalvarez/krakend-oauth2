package org.jla.mpi.api.service

import jakarta.inject.Singleton
import org.jla.mpi.api.model.Patient
import org.jla.mpi.api.repository.PatientRepository

@Singleton
class PatientService constructor(private val patientRepository: PatientRepository) {

    fun getPatient(id: String) : Patient? {
        return patientRepository.findPatientById(id);
    }

}
