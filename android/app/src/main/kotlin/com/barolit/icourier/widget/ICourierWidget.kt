package com.barolit.icourier.widget

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.Color
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color as ComposeColor
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
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
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

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

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetRefreshScheduler.sync(context, WidgetSessionStore.read(context) != null)
    }

    override fun onDisabled(context: Context) {
        WidgetRefreshScheduler.cancel(context)
        super.onDisabled(context)
    }
}

@Composable
private fun WidgetContent(context: Context, state: WidgetViewState) {
    val widgetSize = LocalSize.current
    val isWide = usesWideWidgetLayout(widgetSize.width.value)
    val usesStatusList = usesCompactStatusList(
        widthDp = widgetSize.width.value,
        heightDp = widgetSize.height.value,
    )
    val contentPrimary = if (state.stale) state.muted else state.primary
    val contentText = if (state.stale) state.muted else state.text
    val brandLabel = if (state.stale) {
        "${state.brandName} · ${state.generatedAtLabel}"
    } else {
        state.brandName
    }
    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(state.deepLink)).apply {
        setClass(context, MainActivity::class.java)
    }
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(widgetColorProvider(state.surface))
            .clickable(actionStartActivity(intent))
            .padding(if (isWide) 16.dp else 14.dp),
    ) {
        BrandHeader(context, state.logoAsset, brandLabel, contentText)
        Spacer(GlanceModifier.height(8.dp))
        if (!state.signedIn) {
            Text(
                text = "Inicia sesión",
                style = TextStyle(color = widgetColorProvider(state.muted), fontSize = 14.sp),
            )
            return@Column
        }
        if (isWide) {
            WideSummary(state, contentPrimary, contentText)
        } else if (usesStatusList) {
            CompactSummary(state, contentPrimary, contentText)
        } else {
            MinimalSummary(state, contentPrimary, contentText)
        }
    }
}

@Composable
private fun MinimalSummary(
    state: WidgetViewState,
    contentPrimary: Int,
    contentText: Int,
) {
    Row(modifier = GlanceModifier.fillMaxWidth()) {
        SummaryMetric(
            title = "Total",
            value = state.total,
            labelColor = state.muted,
            valueColor = contentText,
            modifier = GlanceModifier.defaultWeight(),
            valueSize = 25,
        )
        Spacer(GlanceModifier.width(10.dp))
        SummaryMetric(
            title = "Disponibles",
            value = state.available,
            labelColor = state.muted,
            valueColor = contentPrimary,
            modifier = GlanceModifier.defaultWeight(),
            valueSize = 25,
        )
    }
}

@Composable
private fun CompactSummary(
    state: WidgetViewState,
    contentPrimary: Int,
    contentText: Int,
) {
    Column(
        modifier = GlanceModifier.fillMaxWidth(),
    ) {
        Text(
            text = packageCountLabel(state.total),
            style = TextStyle(
                color = widgetColorProvider(contentText),
                fontWeight = FontWeight.Bold,
                fontSize = 23.sp,
            ),
        )
        Spacer(GlanceModifier.height(5.dp))
        CompactStatusRow(
            "Disponibles",
            state.available,
            contentText,
            contentPrimary,
        )
        CompactStatusRow(
            "En proceso",
            state.inProcess,
            contentText,
            contentPrimary,
        )
        CompactStatusRow(
            "En ruta",
            state.inRoute,
            contentText,
            contentPrimary,
        )
        CompactStatusRow(
            "Retenidos",
            state.retained,
            contentText,
            contentPrimary,
        )
    }
}

@Composable
private fun CompactStatusRow(
    title: String,
    value: Int,
    labelColor: Int,
    valueColor: Int,
) {
    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .height(38.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = title,
            maxLines = 1,
            style = TextStyle(
                color = widgetColorProvider(labelColor),
                fontSize = 14.sp,
            ),
        )
        Spacer(GlanceModifier.defaultWeight())
        Text(
            text = value.toString(),
            style = TextStyle(
                color = widgetColorProvider(valueColor),
                fontWeight = FontWeight.Bold,
                fontSize = 17.sp,
            ),
        )
    }
}

@Composable
private fun WideSummary(
    state: WidgetViewState,
    contentPrimary: Int,
    contentText: Int,
) {
    Text(
        text = packageCountLabel(state.total),
        style = TextStyle(
            color = widgetColorProvider(contentText),
            fontWeight = FontWeight.Bold,
            fontSize = 23.sp,
        ),
    )
    Text(
        text = "Resumen por estatus",
        style = TextStyle(color = widgetColorProvider(state.muted), fontSize = 11.sp),
    )
    Spacer(GlanceModifier.height(8.dp))
    Row(modifier = GlanceModifier.fillMaxWidth()) {
        SummaryMetric(
            "Disponibles",
            state.available,
            state.muted,
            contentPrimary,
            GlanceModifier.defaultWeight(),
        )
        SummaryMetric(
            "En proceso",
            state.inProcess,
            state.muted,
            contentPrimary,
            GlanceModifier.defaultWeight(),
        )
        SummaryMetric(
            "En ruta",
            state.inRoute,
            state.muted,
            contentPrimary,
            GlanceModifier.defaultWeight(),
        )
        SummaryMetric(
            "Retenidos",
            state.retained,
            state.muted,
            contentPrimary,
            GlanceModifier.defaultWeight(),
        )
    }
}

@Composable
private fun SummaryMetric(
    title: String,
    value: Int,
    labelColor: Int,
    valueColor: Int,
    modifier: GlanceModifier,
    valueSize: Int = 19,
) {
    Column(modifier = modifier) {
        Text(
            text = title,
            maxLines = 1,
            style = TextStyle(color = widgetColorProvider(labelColor), fontSize = 10.sp),
        )
        Text(
            text = value.toString(),
            maxLines = 1,
            style = TextStyle(
                color = widgetColorProvider(valueColor),
                fontWeight = FontWeight.Bold,
                fontSize = valueSize.sp,
            ),
        )
    }
}

@Composable
private fun BrandHeader(
    context: Context,
    logoAsset: String,
    brandLabel: String,
    contentText: Int,
) {
    val logo = BitmapFactory.decodeFile(context.getFileStreamPath(logoAsset).path)
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = brandLabel,
            style = TextStyle(
                color = widgetColorProvider(contentText),
                fontWeight = FontWeight.Bold,
                fontSize = 13.sp,
            ),
        )
        Spacer(GlanceModifier.defaultWeight())
        if (logo != null) {
            Image(
                provider = ImageProvider(logo),
                contentDescription = "Icono de la aplicación",
                modifier = GlanceModifier.width(28.dp).height(28.dp),
            )
        }
    }
}

private data class WidgetViewState(
    val brandName: String,
    val logoAsset: String,
    val primary: Int,
    val surface: Int,
    val text: Int,
    val muted: Int,
    val signedIn: Boolean,
    val stale: Boolean,
    val generatedAtLabel: String,
    val total: Int,
    val available: Int,
    val inProcess: Int,
    val inRoute: Int,
    val retained: Int,
    val deepLink: String,
) {
    companion object {
        fun empty() = WidgetViewState(
            brandName = "iCourier",
            logoAsset = "widget_logo.png",
            primary = Color.DKGRAY,
            surface = Color.WHITE,
            text = Color.BLACK,
            muted = Color.GRAY,
            signedIn = false,
            stale = false,
            generatedAtLabel = "",
            total = 0,
            available = 0,
            inProcess = 0,
            inRoute = 0,
            retained = 0,
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
        WidgetViewState(
            brandName = brand.getString("slug"),
            logoAsset = brand.optString("logoAsset", "widget_logo.png"),
            primary = Color.parseColor(brand.getString("primary")),
            surface = Color.parseColor(brand.getString("surface")),
            text = Color.parseColor(brand.getString("text")),
            muted = Color.parseColor(brand.getString("muted")),
            signedIn = session.getBoolean("signedIn"),
            stale = isSnapshotStale(root.optString("staleAfter")),
            generatedAtLabel = formatSnapshotTime(root.optString("generatedAt")),
            total = counts.getInt("total"),
            available = counts.getInt("disponible"),
            inProcess = counts.getInt("enProceso"),
            inRoute = counts.getInt("enRuta"),
            retained = counts.getInt("retenido"),
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

private fun formatSnapshotTime(value: String): String = runCatching {
    DateTimeFormatter
        .ofLocalizedTime(FormatStyle.SHORT)
        .withLocale(Locale.getDefault())
        .withZone(ZoneId.systemDefault())
        .format(Instant.parse(value))
}.getOrDefault("--:--")

internal fun widgetColorProvider(color: Int): ColorProvider =
    ColorProvider(ComposeColor(color))

internal fun usesWideWidgetLayout(widthDp: Float): Boolean = widthDp >= 280f

internal fun usesCompactStatusList(widthDp: Float, heightDp: Float): Boolean =
    !usesWideWidgetLayout(widthDp) && heightDp >= 180f

internal fun packageCountLabel(total: Int): String =
    "$total ${if (total == 1) "paquete" else "paquetes"}"
