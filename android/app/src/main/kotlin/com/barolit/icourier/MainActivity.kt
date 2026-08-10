package com.barolit.icourier

import com.barolit.icourier.widget.ICourierWidget
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
                    if (payload == null) {
                        result.error("invalid_payload", "Missing widget payload", null)
                        return@setMethodCallHandler
                    }
                    preferences.edit().putString(key, payload).apply()
                    refreshWidgets()
                    result.success(null)
                }
                "clear" -> {
                    preferences.edit().remove(key).apply()
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
    }
}
