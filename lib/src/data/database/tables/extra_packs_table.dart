import 'package:drift/drift.dart';
import 'data_plans_table.dart';

/// Relational SQLite table storing extra addon booster data packs.
@DataClassName('ExtraPackEntity')
class ExtraPacksTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get planHashedSubscriberId =>
      text().references(DataPlansTable, #hashedSubscriberId, onDelete: KeyAction.cascade)();
  IntColumn get extraBytes => integer()();
  IntColumn get usedBytes => integer().withDefault(const Constant(0))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get expiryDate => dateTime()();
  BoolColumn get isExpired => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().withDefault(const Constant(''))();
}
