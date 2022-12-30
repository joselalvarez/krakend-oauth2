package org.jla.ehr.api.model

import io.micronaut.serde.annotation.Serdeable

@Serdeable
data class Ehr(
    val ehrId: String,
    val document: String
)
