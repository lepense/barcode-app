package com.barcodeapp.barcode_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class BarcodeWalletWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val merchantName = widgetData.getString("widget_merchant_name", "— Kart yok —") ?: "— Kart yok —"
            val barcodeValue = widgetData.getString("widget_barcode_value", "") ?: ""
            val barcodeType  = widgetData.getString("widget_barcode_type",  "QR") ?: "QR"
            val cardId       = widgetData.getString("widget_card_id", "") ?: ""
            val initial      = if (merchantName.isNotEmpty() && merchantName[0].isLetter())
                                   merchantName[0].uppercaseChar().toString() else "B"

            val views = RemoteViews(context.packageName, R.layout.barcode_wallet_widget)
            views.setTextViewText(R.id.widget_merchant_name, merchantName)
            views.setTextViewText(R.id.widget_barcode_value, barcodeValue)
            views.setTextViewText(R.id.widget_barcode_type,  barcodeType)
            views.setTextViewText(R.id.widget_initial, initial)

            // Tap → open app to the card detail screen
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                putExtra("card_id", cardId)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pi = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(android.R.id.content, pi)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
