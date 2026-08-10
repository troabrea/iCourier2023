package com.barolit.icourier.widget

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.barolit.icourier.MainActivity
import org.json.JSONObject
import java.time.Instant

class ICourierWidget : GlanceAppWidget() {
    override val sizeMode: SizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val payload = context
            .getSharedPreferences(MainActivity.WIDGET_PREFERENCES, Context.MODE_PRIVATE)
            .getString(MainActivity.WIDGET_STATE_KEY, null)
        val state = payload?.let(::parseState) ?: WidgetViewState.empty()
        provideContent {
            WidgetContent(context, state)
        }
    }
}

class ICourierWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ICourierWidget()
}

@Composable
private fun WidgetContent(context: Context, state: WidgetViewState) {
    val isWide = LocalSize.current.width >= 180.dp
    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(state.deepLink)).apply {
        setClass(context, MainActivity::class.java)
    }
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ColorProvider(state.surface))
            .clickable(actionStartActivity(intent))
            .padding(16.dp),
    ) {
        Text(
            text = state.brandName,
            style = TextStyle(
                color = ColorProvider(state.text),
                fontWeight = FontWeight.Bold,
                fontSize = 13.sp,
            ),
        )
        Spacer(GlanceModifier.height(8.dp))
        if (!state.signedIn) {
            Text(
                text = "Inicia sesión",
                style = TextStyle(color = ColorProvider(state.muted), fontSize = 14.sp),
            )
            return@Column
        }
        if (state.stale) {
            Text(
                text = "Abre la app para actualizar",
                style = TextStyle(
                    color = ColorProvider(state.text),
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp,
                ),
            )
            return@Column
        }
        Text(
            text = state.available.toString(),
            style = TextStyle(
                color = ColorProvider(state.primary),
                fontWeight = FontWeight.Bold,
                fontSize = if (isWide) 28.sp else 24.sp,
            ),
        )
        Text(
            text = "Disponibles",
            style = TextStyle(color = ColorProvider(state.text), fontSize = 12.sp),
        )
        if (isWide && state.featuredId.isNotEmpty()) {
            Spacer(GlanceModifier.height(8.dp))
            Text(
                text = state.featuredContent,
                maxLines = 1,
                style = TextStyle(
                    color = ColorProvider(state.text),
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp,
                ),
            )
            Text(
                text = state.statusLabel,
                maxLines = 1,
                style = TextStyle(color = ColorProvider(state.muted), fontSize = 12.sp),
            )
            Spacer(GlanceModifier.height(8.dp))
            ProgressRail(state.stageIndex, state.primary, state.muted)
        }
    }
}

@Composable
private fun ProgressRail(stageIndex: Int, primary: Int, muted: Int) {
    Row(modifier = GlanceModifier.fillMaxWidth()) {
        repeat(4) { index ->
            Box(
                modifier = GlanceModifier
                    .width(24.dp)
                    .height(5.dp)
                    .background(ColorProvider(if (index <= stageIndex) primary else muted)),
            ) {}
            if (index < 3) Spacer(GlanceModifier.width(4.dp))
        }
    }
}

private data class WidgetViewState(
    val brandName: String,
    val primary: Int,
    val surface: Int,
    val text: Int,
    val muted: Int,
    val signedIn: Boolean,
    val stale: Boolean,
    val available: Int,
    val featuredId: String,
    val featuredContent: String,
    val statusLabel: String,
    val stageIndex: Int,
    val deepLink: String,
) {
    companion object {
        fun empty() = WidgetViewState(
            brandName = "iCourier",
            primary = Color.DKGRAY,
            surface = Color.WHITE,
            text = Color.BLACK,
            muted = Color.GRAY,
            signedIn = false,
            stale = false,
            available = 0,
            featuredId = "",
            featuredContent = "",
            statusLabel = "",
            stageIndex = 0,
            deepLink = "icourier://login",
        )
    }
}

private fun parseState(payload: String): WidgetViewState {
    return runCatching {
        val root = JSONObject(payload)
        val brand = root.getJSONObject("brand")
        val session = root.getJSONObject("session")
        val counts = root.getJSONObject("counts")
        val featured = root.optJSONObject("featured")
        WidgetViewState(
            brandName = brand.getString("slug"),
            primary = Color.parseColor(brand.getString("primary")),
            surface = Color.parseColor(brand.getString("surface")),
            text = Color.parseColor(brand.getString("text")),
            muted = Color.parseColor(brand.getString("muted")),
            signedIn = session.getBoolean("signedIn"),
            stale = isSnapshotStale(root.optString("staleAfter")),
            available = counts.getInt("disponible"),
            featuredId = featured?.optString("id").orEmpty(),
            featuredContent = featured?.optString("contenido").orEmpty(),
            statusLabel = featured?.optString("estadoLabel").orEmpty(),
            stageIndex = featured?.optInt("stageIndex") ?: 0,
            deepLink = root.getString("deepLink"),
        )
    }.getOrElse { WidgetViewState.empty() }
}

internal fun isSnapshotStale(
    staleAfter: String,
    now: Instant = Instant.now(),
): Boolean = runCatching {
    !Instant.parse(staleAfter).isAfter(now)
}.getOrDefault(true)
