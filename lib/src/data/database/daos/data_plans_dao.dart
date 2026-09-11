import 'package:drift/drift.dart';
import '../../models/data_plan.dart';
import '../../models/data_plan_extra.dart';
import '../app_database.dart';
import '../tables/data_plans_table.dart';
import '../tables/extra_packs_table.dart';

part 'data_plans_dao.g.dart';

/// Data Access Object providing reactive streams and asynchronous CRUD for data plans and addon packs.
@DriftAccessor(tables: [DataPlansTable, ExtraPacksTable])
class DataPlansDao extends DatabaseAccessor<AppDatabase> with _$DataPlansDaoMixin {
  DataPlansDao(super.db);

  /// Streams all configured SIM data plans ordered by SIM slot index.
  Stream<List<DataPlan>> watchAllPlans() {
    final query = select(dataPlansTable)
      ..orderBy([(t) => OrderingTerm(expression: t.simSlotIndex)]);
    return query.watch().map((rows) => rows.map(_entityToPlan).toList(growable: false));
  }

  /// Fetches all configured SIM data plans.
  Future<List<DataPlan>> getAllPlans() async {
    final query = select(dataPlansTable)
      ..orderBy([(t) => OrderingTerm(expression: t.simSlotIndex)]);
    final rows = await query.get();
    return rows.map(_entityToPlan).toList(growable: false);
  }

  /// Retrieves a specific plan by its hashed subscriber ID.
  Future<DataPlan?> getPlanByHashedId(String hashedId) async {
    final query = select(dataPlansTable)..where((t) => t.hashedSubscriberId.equals(hashedId));
    final entity = await query.getSingleOrNull();
    return entity != null ? _entityToPlan(entity) : null;
  }

  /// Streams a specific plan by its hashed subscriber ID.
  Stream<DataPlan?> watchPlanByHashedId(String hashedId) {
    final query = select(dataPlansTable)..where((t) => t.hashedSubscriberId.equals(hashedId));
    return query.watchSingleOrNull().map((entity) => entity != null ? _entityToPlan(entity) : null);
  }

  /// Inserts or updates an existing SIM data plan.
  Future<void> insertOrUpdatePlan(DataPlan plan) async {
    await into(dataPlansTable).insertOnConflictUpdate(_planToCompanion(plan));
  }

  /// Deletes a SIM data plan and all associated addon booster packs.
  Future<int> deletePlan(String hashedId) async {
    return (delete(dataPlansTable)..where((t) => t.hashedSubscriberId.equals(hashedId))).go();
  }

  /// Streams active extra addon packs for a specific SIM plan.
  Stream<List<DataPlanExtra>> watchExtraPacks(String planHashedId) {
    final query = select(extraPacksTable)
      ..where((t) => t.planHashedSubscriberId.equals(planHashedId))
      ..orderBy([(t) => OrderingTerm(expression: t.expiryDate)]);
    return query.watch().map((rows) => rows.map(_entityToExtra).toList(growable: false));
  }

  /// Fetches extra addon packs for a specific SIM plan.
  Future<List<DataPlanExtra>> getExtraPacks(String planHashedId) async {
    final query = select(extraPacksTable)
      ..where((t) => t.planHashedSubscriberId.equals(planHashedId))
      ..orderBy([(t) => OrderingTerm(expression: t.expiryDate)]);
    final rows = await query.get();
    return rows.map(_entityToExtra).toList(growable: false);
  }

  /// Inserts a new extra addon pack.
  Future<int> insertExtraPack(DataPlanExtra extra) async {
    return into(extraPacksTable).insert(_extraToCompanion(extra));
  }

  /// Updates an existing extra addon pack.
  Future<bool> updateExtraPack(DataPlanExtra extra) async {
    return update(extraPacksTable).replace(_extraToCompanion(extra));
  }

  /// Deletes an extra addon pack by its primary ID.
  Future<int> deleteExtraPack(int id) async {
    return (delete(extraPacksTable)..where((t) => t.id.equals(id))).go();
  }

  // --- Entity Mapping Helpers ---

  static DataPlan _entityToPlan(DataPlanEntity entity) {
    return DataPlan(
      hashedSubscriberId: entity.hashedSubscriberId,
      encryptedSubscriberId: entity.encryptedSubscriberId,
      simSlotIndex: entity.simSlotIndex,
      carrierName: entity.carrierName,
      quotaBytes: entity.quotaBytes,
      billingCycleStartDay: entity.billingCycleStartDay,
      cycleInterval: entity.cycleInterval,
      customIntervalDays: entity.customIntervalDays,
      rolloverEnabled: entity.rolloverEnabled,
      excludedUids: entity.excludedUids,
      cardColorIndex: entity.cardColorIndex,
      customNote: entity.customNote,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static DataPlansTableCompanion _planToCompanion(DataPlan plan) {
    return DataPlansTableCompanion(
      hashedSubscriberId: Value(plan.hashedSubscriberId),
      encryptedSubscriberId: Value(plan.encryptedSubscriberId),
      simSlotIndex: Value(plan.simSlotIndex),
      carrierName: Value(plan.carrierName),
      quotaBytes: Value(plan.quotaBytes),
      billingCycleStartDay: Value(plan.billingCycleStartDay),
      cycleInterval: Value(plan.cycleInterval),
      customIntervalDays: Value(plan.customIntervalDays),
      rolloverEnabled: Value(plan.rolloverEnabled),
      excludedUids: Value(plan.excludedUids),
      cardColorIndex: Value(plan.cardColorIndex),
      customNote: Value(plan.customNote),
      createdAt: Value(plan.createdAt),
      updatedAt: Value(plan.updatedAt),
    );
  }

  static DataPlanExtra _entityToExtra(ExtraPackEntity entity) {
    return DataPlanExtra(
      id: entity.id,
      planHashedSubscriberId: entity.planHashedSubscriberId,
      extraBytes: entity.extraBytes,
      usedBytes: entity.usedBytes,
      startDate: entity.startDate,
      expiryDate: entity.expiryDate,
      isExpired: entity.isExpired,
      note: entity.note,
    );
  }

  static ExtraPacksTableCompanion _extraToCompanion(DataPlanExtra extra) {
    return ExtraPacksTableCompanion(
      id: extra.id > 0 ? Value(extra.id) : const Value.absent(),
      planHashedSubscriberId: Value(extra.planHashedSubscriberId),
      extraBytes: Value(extra.extraBytes),
      usedBytes: Value(extra.usedBytes),
      startDate: Value(extra.startDate),
      expiryDate: Value(extra.expiryDate),
      isExpired: Value(extra.isExpired),
      note: Value(extra.note),
    );
  }
}
