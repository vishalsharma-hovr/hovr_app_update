package com.ridehovr.hovr_app_update

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class VersionCompareTest {
    @Test
    fun emptyServerVersionDoesNotRequireUpdate() {
        assertFalse(VersionCompare.isUpdateRequired("", "1.0.0"))
    }

    @Test
    fun matchingVersionsAfterTrimDoNotRequireUpdate() {
        assertFalse(VersionCompare.isUpdateRequired(" 6.2.4 ", "6.2.4"))
    }

    @Test
    fun differentVersionsRequireUpdate() {
        assertTrue(VersionCompare.isUpdateRequired("6.3.0", "6.2.4"))
    }
}
