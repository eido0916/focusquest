package dev.focusquest.focusquest

import org.junit.Assert.*
import org.junit.Test

class FocusAllowanceTest {
    @Test fun warningReturnsAtExactlyOneMinuteAndOtherAppsStillWarn() {
        val allowance = FocusAllowance()
        assertFalse(allowance.permits("app.a", 1000L))
        allowance.allow("app.a", 1000L)
        assertTrue(allowance.permits("app.a", 60999L))
        assertFalse(allowance.permits("app.a", 61000L))
        assertFalse(allowance.permits("app.b", 1001L))
        assertFalse(allowance.permits(null, 1001L))
    }

    @Test fun switchingAppsDoesNotExtendTheAllowanceAndRestorationIsBounded() {
        val allowance = FocusAllowance()
        allowance.allow("app.a", 1000L)
        assertFalse(allowance.permits("app.b", 2000L))
        assertTrue(allowance.permits("app.a", 3000L))
        assertFalse(allowance.permits("app.a", 62000L))
        allowance.allow("app.a", 100000L, 1000000L)
        assertFalse(allowance.permits("app.a", 160000L))
        allowance.allow("app.a", 100000L, -1L)
        assertFalse(allowance.permits("app.a", 100000L))
    }
}
