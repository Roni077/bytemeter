import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import '../models/enums.dart';
import 'converters/type_converters.dart';
import 'daos/data_plans_dao.dart';
import 'tables/data_plans_table.dart';
import 'tables/extra_packs_table.dart';

part 'app_database.g.dart';

/// Central Drift SQLite database for ByteMeter multi-SIM plans and addon packs.
@DriftDatabase(
  tables: [DataPlansTable, ExtraPacksTable],
  daos: [DataPlansDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  /// Factory constructor for unit testing with an in-memory SQLite database.
  factory AppDatabase.inMemory() {
    return AppDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
          await customStatement('PRAGMA journal_mode = WAL;');
          await customStatement('PRAGMA synchronous = NORMAL;');
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_extra_packs_plan ON extra_packs_table (plan_hashed_subscriber_id);',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_extra_packs_expiry ON extra_packs_table (expiry_date);',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_data_plans_slot ON data_plans_table (sim_slot_index);',
          );
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File('${dbFolder.path}/bytemeter_db.sqlite');
    return NativeDatabase.createInBackground(file);
  });
}
