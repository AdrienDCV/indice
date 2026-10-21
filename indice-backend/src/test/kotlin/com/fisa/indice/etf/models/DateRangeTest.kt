package com.fisa.indice.etf.models

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import java.time.LocalDate
import kotlin.test.assertEquals

class DateRangeTest {

    @Test
    fun `should accept a range of a single day`() {
        val day = LocalDate.parse("2026-10-19")

        assertEquals(day, DateRange(day, day).endDate)
    }

    @Test
    fun `should reject a range that ends before it starts`() {
        assertThrows<IllegalArgumentException> { DateRange(LocalDate.parse("2026-10-19"), LocalDate.parse("2026-10-18")) }
    }
}
