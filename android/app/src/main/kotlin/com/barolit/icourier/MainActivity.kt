package com.barolit.icourier

import com.barolit.icourier.widget.ICourierWidget
import com.barolit.icourier.widget.WidgetRefreshScheduler
import com.barolit.icourier.widget.WidgetSessionStore
import androidx.glance.appwidget.updateAll
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIDGET_CHANNEL,
        ).setMethodCallHandler { call, result ->
            val arguments = call.arguments as? Map<*, *>
            val key = arguments?.get("key") as? String ?: WIDGET_STATE_KEY
            val preferences = getSharedPreferences(WIDGET_PREFERENCES, MODE_PRIVATE)
            when (call.method) {
                "write" -> {
                    val payload = arguments?.get("payload") as? String
                    val logoFile = arguments?.get("logoFile") as? String
                    val logoBytes = arguments?.get("logoBytes") as? ByteArray
                    val sessionId = arguments?.get("sessionId") as? String
                    val companyId = arguments?.get("companyId") as? String
                    val endpoint = arguments?.get("endpoint") as? String
                    if (
                        payload == null ||
                        logoFile == null ||
                        logoBytes == null ||
                        sessionId == null ||
                        companyId == null ||
                        endpoint == null ||
                        logoFile != java.io.File(logoFile).name
                    ) {
                        result.error(
                            "invalid_payload",
                            "Missing widget payload or brand icon",
                            null,
                        )
                        return@setMethodCallHandler
                    }
                    WidgetSessionStore.write(this, sessionId)
                    openFileOutput(logoFile, MODE_PRIVATE).use { it.write(logoBytes) }
                    preferences.edit()
                        .putString(key, payload)
                        .putString(WIDGET_COMPANY_ID_KEY, companyId)
                        .putString(WIDGET_ENDPOINT_KEY, endpoint)
                        .apply()
                    WidgetRefreshScheduler.sync(this, sessionId.isNotEmpty())
                    refreshWidgets()
                    result.success(null)
                }
                "clear" -> {
                    WidgetSessionStore.clear(this)
                    preferences.edit()
                        .remove(key)
                        .remove(WIDGET_COMPANY_ID_KEY)
                        .remove(WIDGET_ENDPOINT_KEY)
                        .apply()
                    WidgetRefreshScheduler.cancel(this)
                    refreshWidgets()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun refreshWidgets() {
        CoroutineScope(Dispatchers.Default).launch {
            ICourierWidget().updateAll(this@MainActivity)
        }
    }

    companion object {
        const val WIDGET_CHANNEL = "icourier/widget_state"
        const val WIDGET_PREFERENCES = "icourier_widget_state"
        const val WIDGET_STATE_KEY = "widget_state"
        const val WIDGET_COMPANY_ID_KEY = "widget_company_id"
        const val WIDGET_ENDPOINT_KEY = "widget_endpoint"
    }
}
