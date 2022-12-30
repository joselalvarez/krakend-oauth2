package org.jla.mpi.api.util

import com.nimbusds.jwt.JWT
import com.nimbusds.jwt.JWTParser
import io.micronaut.http.HttpHeaders
import jakarta.inject.Singleton
import org.slf4j.LoggerFactory
import java.text.ParseException

@Singleton
class JWTUtil {

    private val logger = LoggerFactory.getLogger(JWTUtil::class.java)

    fun tokenIsPresent(headers: HttpHeaders): Boolean {
        return headers.authorization
            .filter { s -> s.startsWith("Bearer ") }
            .isPresent
    }

    fun getTokenFrom(headers: HttpHeaders): JWT? {
        return try {
            val token = headers.authorization
                .filter { s -> s.startsWith("Bearer ") }
                .map { s -> s.removePrefix("Bearer ") }
                .orElse(null)
            token?.let { JWTParser.parse(token) }
        }catch (e: ParseException) {
            logger.error("Token parsing error: '${e.toString()}'")
            null
        }

    }
}