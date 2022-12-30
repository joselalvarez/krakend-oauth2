package org.jla.ehr.api.model

import io.micronaut.serde.annotation.Serdeable

@Serdeable
data class Patient(
    val id: String,
    val ehrId: String,
    val fullName: String
)
