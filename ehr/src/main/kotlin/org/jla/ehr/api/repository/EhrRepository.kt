package org.jla.ehr.api.repository

import jakarta.inject.Singleton
import org.jla.ehr.api.model.Ehr

@Singleton
class EhrRepository {
    private val index: HashMap<String, Ehr> = HashMap<String, Ehr>()

    fun merge(ehr: Ehr): Ehr {
        index[ehr.ehrId] = ehr
        return ehr
    }

    fun findAll(): List<Ehr> {
        return ArrayList<Ehr>(index.values)
    }
}