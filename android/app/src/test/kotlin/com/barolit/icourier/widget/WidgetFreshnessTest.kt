package com.barolit.icourier.widget

import java.time.Instant
import org.json.JSONArray
import org.junit.Assert.assertFalse
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetFreshnessTest {
    private val now = Instant.parse("2026-08-10T13:00:00Z")

    @Test
    fun freshSnapshotRemainsVisible() {
        assertFalse(isSnapshotStale("2026-08-10T13:00:01Z", now))
    }

    @Test
    fun dartFractionalUtcTimestampRemainsVisible() {
        assertFalse(isSnapshotStale("2026-08-10T13:00:00.001Z", now))
    }

    @Test
    fun snapshotExpiresAtStaleAfter() {
        assertTrue(isSnapshotStale("2026-08-10T13:00:00Z", now))
    }

    @Test
    fun malformedSnapshotFailsClosed() {
        assertTrue(isSnapshotStale("invalid", now))
    }

    @Test
    fun remoteRefreshWaitsThirtyMinutes() {
        assertFalse(
            WidgetRemoteRefreshWorker.needsRefresh(
                "2026-08-10T12:30:01Z",
                now,
            ),
        )
        assertTrue(
            WidgetRemoteRefreshWorker.needsRefresh(
                "2026-08-10T12:30:00Z",
                now,
            ),
        )
    }

    @Test
    fun pushRefreshBypassesThirtyMinuteWindow() {
        assertTrue(
            WidgetRemoteRefreshWorker.needsRefresh(
                generatedAt = "2026-08-10T12:59:59Z",
                now = now,
                forceRefresh = true,
            ),
        )
    }

    @Test
    fun backgroundSummaryMatchesFlutterCategories() {
        val packages = JSONArray(
            """[
                {"estatus":"Disponible","disponible":true,"retenido":false,"progreso":4},
                {"estatus":"Aduana","disponible":false,"retenido":true,"progreso":3},
                {"estatus":"Embarcado","disponible":false,"retenido":false,"progreso":2},
                {"estatus":"Recibido para procesar","disponible":false,"retenido":false,"progreso":1}
            ]""",
        )

        val counts = WidgetRemoteRefreshWorker.summarize(packages)

        assertEquals(4, counts.getInt("total"))
        assertEquals(1, counts.getInt("disponible"))
        assertEquals(1, counts.getInt("retenido"))
        assertEquals(1, counts.getInt("enRuta"))
        assertEquals(1, counts.getInt("enProceso"))
    }

    @Test
    fun whitelabelArgbUsesFixedColorInsteadOfResourceId() {
        val provider = widgetColorProvider(0xFFFFFFFF.toInt())

        assertEquals("FixedColorProvider", provider.javaClass.simpleName)
    }

    @Test
    fun narrowWidgetUsesListUntilColumnsHaveEnoughWidth() {
        assertFalse(usesWideWidgetLayout(190f))
        assertFalse(usesWideWidgetLayout(279f))
        assertTrue(usesWideWidgetLayout(280f))
        assertTrue(usesCompactStatusList(widthDp = 190f, heightDp = 230f))
        assertFalse(usesCompactStatusList(widthDp = 190f, heightDp = 150f))
        assertFalse(usesCompactStatusList(widthDp = 280f, heightDp = 230f))
    }

    @Test
    fun packageCountUsesSpanishSingularAndPlural() {
        assertEquals("1 paquete", packageCountLabel(1))
        assertEquals("2 paquetes", packageCountLabel(2))
    }
}
