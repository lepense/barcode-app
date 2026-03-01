import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';

/// Result of a sync operation.
class SyncResult {
  final int pushed;
  final String? error;

  const SyncResult.success(this.pushed) : error = null;
  const SyncResult.failure(this.error) : pushed = 0;

  bool get isSuccess => error == null;
}

/// Syncs unsynced local cards to Firestore via the Cloud Function.
///
/// Strategy: **push-only** (same-device encrypted backup).
/// Pull is deferred — device-specific AES keys make cross-device pull
/// non-trivial without server-side key management.
class SyncService {
  final AppDatabase _db;

  SyncService(this._db);

  Future<SyncResult> sync() async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return const SyncResult.failure('Not authenticated');
      }

      final unsynced = await _db.cardsDao.getUnsyncedCards();
      if (unsynced.isEmpty) return const SyncResult.success(0);

      final payload = unsynced
          .map((c) => {
                'localId': c.id.toString(),
                if (c.remoteId != null) 'remoteId': c.remoteId,
                'merchantName': c.merchantName,
                'barcodeType': c.barcodeType,
                'barcodeValueEncrypted': c.barcodeValueEncrypted,
                if (c.coverDesignId != null) 'coverDesignId': c.coverDesignId,
                'updatedAt': c.updatedAt.toIso8601String(),
              })
          .toList();

      final response = await http.post(
        Uri.parse(AppConstants.syncPushUrl),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $idToken',
        },
        body: jsonEncode({'cards': payload}),
      );

      if (response.statusCode != 200) {
        debugPrint('Sync push failed [${response.statusCode}]: ${response.body}');
        return SyncResult.failure('Server error ${response.statusCode}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (body['results'] as List).cast<Map<String, dynamic>>();

      int synced = 0;
      for (final r in results) {
        final localId = int.tryParse(r['localId'] as String? ?? '');
        final remoteId = r['remoteId'] as String?;
        final status = r['status'] as String?;

        if (localId == null || remoteId == null) continue;
        if (status == 'created' || status == 'updated') {
          await _db.cardsDao.markSyncedWithRemoteId(localId, remoteId);
          synced++;
        } else if (status == 'skipped_server_newer') {
          // Server is authoritative — mark synced anyway to avoid re-push.
          await _db.cardsDao.markSynced(localId);
          synced++;
        }
      }

      return SyncResult.success(synced);
    } catch (e) {
      debugPrint('Sync error: $e');
      return SyncResult.failure(e.toString());
    }
  }

  Future<String?> _getIdToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }
}
