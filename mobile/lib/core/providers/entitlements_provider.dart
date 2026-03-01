import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/daos/entitlements_dao.dart';
import '../../features/iap/domain/entitlements_model.dart';
import 'database_provider.dart';

/// Provides the [EntitlementsDao].
final entitlementsDaoProvider = Provider<EntitlementsDao>((ref) {
  return ref.watch(databaseProvider).entitlementsDao;
});

/// Streams the user's current [EntitlementsModel], updating whenever the DB row changes.
final entitlementsProvider = StreamProvider<EntitlementsModel>((ref) {
  final dao = ref.watch(entitlementsDaoProvider);
  return dao.watchCurrent().map((row) {
    if (row == null) return EntitlementsModel.empty;
    final packs = (jsonDecode(row.purchasedPacks) as List)
        .map((e) => e as String)
        .toList();
    return EntitlementsModel(
      proLifetime: row.proLifetime,
      purchasedPacks: packs,
    );
  });
});
