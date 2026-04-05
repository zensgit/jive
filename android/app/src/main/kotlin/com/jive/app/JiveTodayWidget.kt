package com.jive.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.DecimalFormat

/**
 * Android home-screen widget that shows today's spending summary.
 *
 * Data is written to SharedPreferences by the Flutter side
 * ([HomeWidgetUpdater]) and read here in [onUpdate].
 */
class JiveTodayWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE
        )

        // Flutter shared_preferences stores doubles as raw long bits and ints
        // as longs.  Use Double.longBitsToDouble to decode.
        val todayExpense = Double.longBitsToDouble(
            prefs.getLong("flutter.today_expense", 0L)
        )
        val todayIncome = Double.longBitsToDouble(
            prefs.getLong("flutter.today_income", 0L)
        )
        val todayCount = prefs.getLong("flutter.today_count", 0L).toInt()
        val monthExpense = Double.longBitsToDouble(
            prefs.getLong("flutter.month_expense", 0L)
        )

        val fmt = DecimalFormat("#,##0.00")

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_today_summary)

            views.setTextViewText(R.id.widget_today_expense, "¥${fmt.format(todayExpense)}")
            views.setTextViewText(R.id.widget_today_income, "¥${fmt.format(todayIncome)}")
            views.setTextViewText(R.id.widget_today_count, "${todayCount}笔")
            views.setTextViewText(R.id.widget_month_expense, "本月 ¥${fmt.format(monthExpense)}")

            // Tap anywhere on the widget to open the app.
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
