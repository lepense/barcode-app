import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../features/iap/data/iap_service.dart';
import 'entitlements_provider.dart';

/// Provides the [IapService] singleton, initialised once.
///
/// The FutureProvider ensures [IapService.init] completes before the service
/// is used by the UI.
final iapServiceProvider = FutureProvider<IapService>((ref) async {
  final dao = ref.watch(entitlementsDaoProvider);
  final service = IapService(InAppPurchase.instance, dao);
  await service.init();
  ref.onDispose(service.dispose);
  return service;
});
