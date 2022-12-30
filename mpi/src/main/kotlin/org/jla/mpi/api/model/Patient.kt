package org.jla.mpi.api.model

import io.micronaut.serde.annotation.Serdeable
import java.util.UUID

@Serdeable
data class Patient(
    val id: String,
    val ehrId: UUID,
    val fullName: String
)