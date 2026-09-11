import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/data_plans_dao.dart';
import '../../data/models/traffic_snapshot.dart';
import '../../data/repositories/data_plan_repository.dart';
import '../../data/repositories/network_usage_repository.dart';
import '../../data/repositories/preferences_repository.dart';
import '../native/native_traffic_bridge.dart';
import '../native/speed_stream_listener.dart';

/// Provider for the native Android platform channel bridge.
final nativeTrafficBridgeProvider = Provider<NativeTrafficBridge>((ref) {
  return NativeTrafficBridge();
});

/// Provider for the sub-second speed event stream listener.
final speedStreamListenerProvider = Provider<SpeedStreamListener>((ref) {
  return SpeedStreamListener();
});

/// Reactive StreamProvider emitting real-time transfer rate snapshots every second.
final speedStreamProvider = StreamProvider.autoDispose<TrafficSnapshot>((ref) {
  final listener = ref.watch(speedStreamListenerProvider);
  return listener.speedStream;
});

/// Singleton provider for the Drift SQLite relational database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Provider for the DataPlans DAO.
final dataPlansDaoProvider = Provider<DataPlansDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.dataPlansDao;
});

/// Provider holding the initialized [SharedPreferences] instance.
/// Overridden in `main.dart` with the asynchronously loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be initialized and overridden in ProviderScope');
});

/// Provider for the reactive preferences repository.
final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final bridge = ref.watch(nativeTrafficBridgeProvider);
  final repo = PreferencesRepository(prefs: prefs, bridge: bridge);
  ref.onDispose(repo.dispose);
  return repo;
});

/// Reactive StreamProvider streaming user preferences updates.
final preferencesStreamProvider = StreamProvider<UserPreferences>((ref) {
  final repo = ref.watch(preferencesRepositoryProvider);
  return repo.preferencesStream;
});

/// Provider for the high-level network usage repository.
final networkUsageRepositoryProvider = Provider<NetworkUsageRepository>((ref) {
  final bridge = ref.watch(nativeTrafficBridgeProvider);
  return NetworkUsageRepository(bridge: bridge);
});

/// Provider for the multi-SIM data plan and budget repository.
final dataPlanRepositoryProvider = Provider<DataPlanRepository>((ref) {
  final dao = ref.watch(dataPlansDaoProvider);
  final bridge = ref.watch(nativeTrafficBridgeProvider);
  return DataPlanRepository(dao: dao, bridge: bridge);
});
