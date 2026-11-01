package com.barolit.icourier.widget

import android.content.Context
import android.util.Log
import androidx.glance.appwidget.updateAll
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.barolit.icourier.MainActivity
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL
import java.time.Duration
import java.time.Instant

class WidgetRemoteRefreshWorker(
    context: Context,
    parameters: WorkerParameters,
) : CoroutineWorker(context, parameters) {
    override suspend fun doWork(): Result {
        val forceRefresh = inputData.getBoolean(FORCE_REFRESH_INPUT_KEY, false)
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
        if (!needsRefresh(root.optString("generatedAt"), forceRefresh = forceRefresh ||
                !hasJourneyCounts(root.getJSONObject("counts")))) {
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
        } catch (error: Exception) {
            // Preserve the last valid snapshot and wait for the next periodic
            // window instead of repeatedly calling the legacy service.
            Log.w(
                "ICourierWidget",
                "Remote refresh failed (${error.javaClass.simpleName}); keeping snapshot.",
            )
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
        internal const val FORCE_REFRESH_INPUT_KEY = "force_widget_refresh"
        private val refreshInterval: Duration = Duration.ofMinutes(30)

        internal fun needsRefresh(
            generatedAt: String,
            now: Instant = Instant.now(),
            forceRefresh: Boolean = false,
        ): Boolean {
            if (forceRefresh) {
                return true
            }
            return runCatching {
                Duration.between(Instant.parse(generatedAt), now) >= refreshInterval
            }.getOrDefault(true)
        }

        internal fun hasJourneyCounts(counts: JSONObject): Boolean =
            counts.has("enTransito") && counts.has("enDistribucion")

        internal fun summarize(packages: JSONArray): JSONObject {
            var available = 0
            var retained = 0
            var inTransit = 0
            var inDistribution = 0
            var inProcess = 0
            for (index in 0 until packages.length()) {
                val packageJson = packages.getJSONObject(index)
                val stage = stage(packageJson)
                if (stage == RemotePackageStage.AVAILABLE) {
                    available++
                } else if (stage == RemotePackageStage.ROUTE) {
                    inTransit++
                } else if (stage == RemotePackageStage.DESTINATION) {
                    inDistribution++
                } else if (stage == RemotePackageStage.ORIGIN) {
                    inProcess++
                }
                if (packageJson.optBoolean("retenido") && !packageJson.optBoolean("disponible") &&
                    stage != RemotePackageStage.DELIVERED) {
                    retained++
                }
            }
            return JSONObject()
                .put("disponible", available)
                .put("retenido", retained)
                .put("enRuta", inTransit + inDistribution)
                .put("enTransito", inTransit)
                .put("enDistribucion", inDistribution)
                .put("enProceso", inProcess)
                .put("total", packages.length())
        }

        private fun stage(packageJson: JSONObject): RemotePackageStage =
            PackageStatusMapper.map(
                status = packageJson.optString("estatus"),
                isAvailable = packageJson.optBoolean("disponible"),
                progress = packageJson.optInt("progreso"),
            )
    }
}
