package com.barolit.icourier.widget

import android.content.Context
import androidx.glance.appwidget.updateAll
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.barolit.icourier.MainActivity
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL
import java.text.Normalizer
import java.time.Duration
import java.time.Instant
import java.util.Locale

class WidgetRemoteRefreshWorker(
    context: Context,
    parameters: WorkerParameters,
) : CoroutineWorker(context, parameters) {
    override suspend fun doWork(): Result {
        val preferences = applicationContext.getSharedPreferences(
            MainActivity.WIDGET_PREFERENCES,
            Context.MODE_PRIVATE,
        )
        val payload = preferences.getString(MainActivity.WIDGET_STATE_KEY, null)
            ?: return Result.success()
        val root = runCatching { JSONObject(payload) }.getOrNull()
            ?: return Result.failure()
        if (!root.getJSONObject("session").optBoolean("signedIn")) {
            return Result.success()
        }
        if (!needsRefresh(root.optString("generatedAt"))) {
            return Result.success()
        }
        val sessionId = WidgetSessionStore.read(applicationContext)
            ?: return Result.success()
        val companyId = preferences.getString(MainActivity.WIDGET_COMPANY_ID_KEY, null)
            ?: return Result.success()
        val endpoint = preferences.getString(MainActivity.WIDGET_ENDPOINT_KEY, null)
            ?: return Result.success()

        return try {
            val packages = fetchPackages(endpoint, companyId, sessionId)
            val now = Instant.now()
            root.put("counts", summarize(packages))
            root.put("generatedAt", now.toString())
            root.put("staleAfter", now.plus(Duration.ofHours(4)).toString())
            preferences.edit()
                .putString(MainActivity.WIDGET_STATE_KEY, root.toString())
                .commit()
            ICourierWidget().updateAll(applicationContext)
            Result.success()
        } catch (_: Exception) {
            // Preserve the last valid snapshot and wait for the next periodic
            // window instead of repeatedly calling the legacy service.
            Result.success()
        }
    }

    private fun fetchPackages(
        endpoint: String,
        companyId: String,
        sessionId: String,
    ): JSONArray {
        val uri = URI(endpoint)
        if (
            uri.scheme != "https" ||
            uri.host != "icourierfunctions2023.azurewebsites.net"
        ) {
            throw IllegalArgumentException("Invalid widget endpoint")
        }
        val connection = URL(endpoint).openConnection() as HttpURLConnection
        return try {
            connection.requestMethod = "POST"
            connection.connectTimeout = 15_000
            connection.readTimeout = 15_000
            connection.doOutput = true
            connection.setRequestProperty("Content-Type", "application/json")
            val request = JSONObject()
                .put("empresaId", companyId)
                .put("sessionId", sessionId)
                .toString()
            connection.outputStream.use { output ->
                output.write(request.toByteArray(Charsets.UTF_8))
            }
            if (connection.responseCode !in 200..299) {
                throw IllegalStateException(
                    "Widget service returned ${connection.responseCode}",
                )
            }
            val response = connection.inputStream.bufferedReader().use { it.readText() }
            JSONArray(response)
        } finally {
            connection.disconnect()
        }
    }

    companion object {
        private val refreshInterval: Duration = Duration.ofMinutes(30)

        private val deliveredTerms = setOf(
            "ENTREGADO AL CLIENTE",
            "ENTREGADO",
            "DELIVERED",
            "BILLED COUNTER",
            "FACTURADO COUNTER",
        )
        private val routeTerms = setOf(
            "EMBARCADO",
            "SHIPMENT SENT",
            "IN TRANSIT",
            "EN RUTA",
        )
        private val destinationTerms = setOf(
            "TRANSFERIDO",
            "EMPACADO",
            "ADUANA",
            "TRANSITO",
            "DISTRIBUCION",
            "RECIBIDO AILA",
            "ALMACEN",
            "WAREHOUSE",
            "CUSTOM",
            "DISTRIBUTION CENTER",
            "PACKED",
            "OUTGOING TRANSFER",
            "DESTINO",
        )
        private val originTerms = setOf(
            "RECIBIDO PARA PROCESAR",
            "LISTO PARA EMBARCACION",
            "RECIBIDO EN ORIGEN",
            "RECIBIDO MIAMI",
            "ORIGIN",
            "RECEIVED",
        )

        internal fun needsRefresh(
            generatedAt: String,
            now: Instant = Instant.now(),
        ): Boolean = runCatching {
            Duration.between(Instant.parse(generatedAt), now) >= refreshInterval
        }.getOrDefault(true)

        internal fun summarize(packages: JSONArray): JSONObject {
            var available = 0
            var retained = 0
            var inRoute = 0
            var inProcess = 0
            for (index in 0 until packages.length()) {
                val packageJson = packages.getJSONObject(index)
                val stage = stage(packageJson)
                if (stage == RemotePackageStage.AVAILABLE) {
                    available++
                } else if (packageJson.optBoolean("retenido")) {
                    retained++
                } else if (
                    stage == RemotePackageStage.ROUTE ||
                    stage == RemotePackageStage.DESTINATION
                ) {
                    inRoute++
                } else if (stage == RemotePackageStage.ORIGIN) {
                    inProcess++
                }
            }
            return JSONObject()
                .put("disponible", available)
                .put("retenido", retained)
                .put("enRuta", inRoute)
                .put("enProceso", inProcess)
                .put("total", packages.length())
        }

        private fun stage(packageJson: JSONObject): RemotePackageStage {
            val status = normalize(packageJson.optString("estatus"))
            if (status in deliveredTerms) {
                return RemotePackageStage.DELIVERED
            }
            if (packageJson.optBoolean("disponible") || "DISPONIBLE" in status) {
                return RemotePackageStage.AVAILABLE
            }
            if (destinationTerms.any(status::contains)) {
                return RemotePackageStage.DESTINATION
            }
            if (routeTerms.any(status::contains)) {
                return RemotePackageStage.ROUTE
            }
            if (originTerms.any(status::contains)) {
                return RemotePackageStage.ORIGIN
            }
            return when (packageJson.optInt("progreso")) {
                0, 1 -> RemotePackageStage.ORIGIN
                2 -> RemotePackageStage.ROUTE
                3 -> RemotePackageStage.DESTINATION
                4 -> RemotePackageStage.AVAILABLE
                else -> RemotePackageStage.DELIVERED
            }
        }

        private fun normalize(value: String): String = Normalizer
            .normalize(value, Normalizer.Form.NFD)
            .replace(Regex("\\p{M}+"), "")
            .uppercase(Locale.ROOT)
            .replace(Regex("[^A-Z0-9]+"), " ")
            .trim()
    }
}

private enum class RemotePackageStage {
    ORIGIN,
    ROUTE,
    DESTINATION,
    AVAILABLE,
    DELIVERED,
}
