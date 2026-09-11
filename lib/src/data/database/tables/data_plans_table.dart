import 'package:drift/drift.dart';
import '../converters/type_converters.dart';

/// Relational SQLite table storing cellular multi-SIM data plans.
@DataClassName('DataPlanEntity')
class DataPlansTable extends Table {
  TextColumn get hashedSubscriberId => text()();
  TextColumn get encryptedSubscriberId => text().nullable()();
  IntColumn get simSlotIndex => integer().withDefault(const Constant(0))();
  TextColumn get carrierName => text().withDefault(const Constant(''))();
  IntColumn get quotaBytes => integer().withDefault(const Constant(0))();
  IntColumn get billingCycleStartDay => integer().withDefault(const Constant(1))();
  TextColumn get cycleInterval =>
      text().map(const TimeIntervalTypeConverter()).withDefault(const Constant('monthly'))();
  IntColumn get customIntervalDays => integer().withDefault(const Constant(30))();
  BoolColumn get rolloverEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get excludedUids =>
      text().map(const IntListConverter()).withDefault(const Constant('[]'))();
  IntColumn get cardColorIndex => integer().withDefault(const Constant(0))();
  TextColumn get customNote => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {hashedSubscriberId};
}
