package com.fisa.indice

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.context.properties.ConfigurationPropertiesScan
import org.springframework.boot.runApplication

@SpringBootApplication
@ConfigurationPropertiesScan
class IndiceApplication

fun main(args: Array<String>) {
	runApplication<IndiceApplication>(*args)
}
