import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder for sync state.
/// TODO: Implement in Phase 4 (Cloud Sync).
enum SyncStatus { idle, syncing, error, success }

final syncStatusProvider = StateProvider<SyncStatus>((ref) {
  return SyncStatus.idle;
});
