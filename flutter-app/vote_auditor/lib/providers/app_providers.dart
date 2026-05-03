import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final electionStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getElectionStatus();
});

final blocksProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getBlocks();
});

final tallyProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getTally();
});

final ledgerVerificationProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.verifyLedger();
});

class RegisteredVotersNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  RegisteredVotersNotifier() : super([]);

  void addVoter(Map<String, dynamic> voter) {
    state = [...state, voter];
  }

  void clear() {
    state = [];
  }
}

final registeredVotersProvider =
    StateNotifierProvider<RegisteredVotersNotifier, List<Map<String, dynamic>>>(
  (ref) => RegisteredVotersNotifier(),
);

class AttackLogNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  AttackLogNotifier() : super([]);

  void addLog(Map<String, dynamic> log) {
    state = [log, ...state];
  }

  void clear() {
    state = [];
  }
}

final attackLogProvider =
    StateNotifierProvider<AttackLogNotifier, List<Map<String, dynamic>>>(
  (ref) => AttackLogNotifier(),
);

class ActivityLogNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  ActivityLogNotifier() : super([]);

  void addLog(String type, String message) {
    state = [
      {'type': type, 'message': message, 'timestamp': DateTime.now().toIso8601String()},
      ...state,
    ];
  }
}

final activityLogProvider =
    StateNotifierProvider<ActivityLogNotifier, List<Map<String, dynamic>>>(
  (ref) => ActivityLogNotifier(),
);
