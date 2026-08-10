package com.barolit.icourier.widget

import java.time.Instant
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetFreshnessTest {
    private val now = Instant.parse("2026-08-10T13:00:00Z")

    @Test
    fun freshSnapshotRemainsVisible() {
        assertFalse(isSnapshotStale("2026-08-10T13:00:01Z", now))
    }

    @Test
    fun snapshotExpiresAtStaleAfter() {
        assertTrue(isSnapshotStale("2026-08-10T13:00:00Z", now))
    }

    @Test
    fun malformedSnapshotFailsClosed() {
        assertTrue(isSnapshotStale("invalid", now))
    }
}
