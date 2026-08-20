package com.barolit.icourier.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

object WidgetRefreshScheduler {
    private const val workName = "icourier_widget_remote_refresh"

    fun sync(context: Context, sessionAvailable: Boolean) {
        val widgetIds = AppWidgetManager.getInstance(context).getAppWidgetIds(
            ComponentName(context, ICourierWidgetReceiver::class.java),
        )
        if (!sessionAvailable || widgetIds.isEmpty()) {
            cancel(context)
            return
        }
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()
        val request = PeriodicWorkRequestBuilder<WidgetRemoteRefreshWorker>(
            30,
            TimeUnit.MINUTES,
            10,
            TimeUnit.MINUTES,
        )
            .setConstraints(constraints)
            .build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            workName,
            ExistingPeriodicWorkPolicy.UPDATE,
            request,
        )
    }

    fun cancel(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(workName)
    }
}
