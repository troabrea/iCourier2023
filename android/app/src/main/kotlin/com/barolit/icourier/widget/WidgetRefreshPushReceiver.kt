package com.barolit.icourier.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class WidgetRefreshPushReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != FIREBASE_MESSAGE_ACTION) {
            return
        }
        WidgetRefreshScheduler.requestImmediate(context)
    }

    private companion object {
        const val FIREBASE_MESSAGE_ACTION = "com.google.android.c2dm.intent.RECEIVE"
    }
}
