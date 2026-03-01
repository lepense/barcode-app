import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/sync/data/sync_service.dart';
import 'database_provider.dart';

enum SyncStatus { idle, syncing, error, success }

/// State exposed to the UI.
class SyncState {
  final SyncStatus status;
  final String? message;

  const SyncState({this.status = SyncStatus.idle, this.message});

  SyncState copyWith({SyncStatus? status, String? message}) => SyncState(
        status: status ?? this.status,
        message: message ?? this.message,
      );
}

/// Notifier that owns a [SyncService] and exposes a [sync] action.
class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _service;

  SyncNotifier(this._service) : super(const SyncState());

  Future<void> sync() async {
    if (state.status == SyncStatus.syncing) return;
    state = state.copyWith(status: SyncStatus.syncing, message: null);

    final result = await _service.sync();

    state = result.isSuccess
        ? state.copyWith(
            status: SyncStatus.success,
            message: result.pushed == 0
                ? 'Already up to date'
                : '${result.pushed} card${result.pushed == 1 ? '' : 's'} synced',
          )
        : state.copyWith(status: SyncStatus.error, message: result.error);
  }
}

final syncProvider =
    StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncNotifier(SyncService(db));
});
