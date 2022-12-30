package org.jla.mpi.api.repository

import jakarta.inject.Singleton
import org.jla.mpi.api.model.Patient
import java.util.*
import kotlin.collections.HashMap

@Singleton
class PatientRepository {

    private val index: HashMap<String, Patient> = HashMap()

    init {
        index["00000000T"] = Patient("00000000T", UUID.randomUUID(), "Nombre0 Apellido0")
        index["11111111H"] = Patient("11111111H", UUID.randomUUID(), "Nombre1 Apellido1")
        index["22222222J"] = Patient("22222222J", UUID.randomUUID(), "Nombre2 Apellido1")
        index["33333333P"] = Patient("33333333P", UUID.randomUUID(), "Nombre3 Apellido1")
        index["44444444A"] = Patient("44444444A", UUID.randomUUID(), "Nombre4 Apellido1")
    }

    fun findPatientById(id: String) : Patient? {
        return index[id.uppercase()]
    }

}