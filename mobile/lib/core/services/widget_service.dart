import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../features/cards/domain/card_model.dart';

/// Updates the Android (and optionally iOS) home screen widget with the
/// currently relevant card.
///
/// Call [updateWithCard] whenever a card is viewed or the card list loads.
class WidgetService {
  WidgetService._();

  static const _appGroupId = 'group.com.barcodeapp.barcode_app'; // iOS only
  static const _androidClass =
      'com.barcodeapp.barcode_app.BarcodeWalletWidgetProvider';

  /// Initialise the home_widget plugin. Call once from main.dart or app.dart.
  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (e) {
      debugPrint('[WidgetService] init error: $e');
    }
  }

  /// Save [card] data to the shared preferences that the native widget reads,
  /// then trigger a widget refresh.
  static Future<void> updateWithCard(LoyaltyCard card) async {
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<String>(
            'widget_merchant_name', card.merchantName),
        HomeWidget.saveWidgetData<String>(
            'widget_barcode_value', card.barcodeValue),
        HomeWidget.saveWidgetData<String>(
            'widget_barcode_type', card.barcodeType),
        HomeWidget.saveWidgetData<String>(
            'widget_card_id', card.id?.toString() ?? ''),
      ]);
      await HomeWidget.updateWidget(
        androidName: _androidClass,
        qualifiedAndroidName: _androidClass,
      );
    } catch (e) {
      debugPrint('[WidgetService] updateWithCard error: $e');
    }
  }

  /// Clear the widget (e.g. after user signs out).
  static Future<void> clear() async {
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<String>('widget_merchant_name', ''),
        HomeWidget.saveWidgetData<String>('widget_barcode_value', ''),
        HomeWidget.saveWidgetData<String>('widget_barcode_type', ''),
        HomeWidget.saveWidgetData<String>('widget_card_id', ''),
      ]);
      await HomeWidget.updateWidget(
        androidName: _androidClass,
        qualifiedAndroidName: _androidClass,
      );
    } catch (e) {
      debugPrint('[WidgetService] clear error: $e');
    }
  }
}
