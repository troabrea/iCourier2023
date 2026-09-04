package com.barolit.icourier.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.workDataOf
import java.util.concurrent.TimeUnit

object WidgetRefreshScheduler {
    private const val periodicWorkName = "icourier_widget_remote_refresh"
    private const val immediateWorkName = "icourier_widget_immediate_refresh"

    fun sync(context: Context, sessionAvailable: Boolean) {
        if (!sessionAvailable || !hasActiveWidget(context)) {
            cancel(context)
            return
        }
        val request = PeriodicWorkRequestBuilder<WidgetRemoteRefreshWorker>(
            30,
            TimeUnit.MINUTES,
            10,
            TimeUnit.MINUTES,
        )
            .setConstraints(networkConstraints())
            .build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            periodicWorkName,
            ExistingPeriodicWorkPolicy.UPDATE,
            request,
        )
    }

    fun requestImmediate(context: Context) {
        if (WidgetSessionStore.read(context) == null || !hasActiveWidget(context)) {
            return
        }
        val request = OneTimeWorkRequestBuilder<WidgetRemoteRefreshWorker>()
            .setConstraints(networkConstraints())
            .setInputData(
                workDataOf(WidgetRemoteRefreshWorker.FORCE_REFRESH_INPUT_KEY to true),
            )
            .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(
            immediateWorkName,
            ExistingWorkPolicy.KEEP,
            request,
        )
    }

    fun cancel(context: Context) {
        WorkManager.getInstance(context).apply {
            cancelUniqueWork(periodicWorkName)
            cancelUniqueWork(immediateWorkName)
        }
    }

    private fun hasActiveWidget(context: Context): Boolean =
        AppWidgetManager.getInstance(context).getAppWidgetIds(
            ComponentName(context, ICourierWidgetReceiver::class.java),
        ).isNotEmpty()

    private fun networkConstraints(): Constraints = Constraints.Builder()
        .setRequiredNetworkType(NetworkType.CONNECTED)
        .build()
}
