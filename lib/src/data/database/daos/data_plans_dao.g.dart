// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_plans_dao.dart';

// ignore_for_file: type=lint
mixin _$DataPlansDaoMixin on DatabaseAccessor<AppDatabase> {
  $DataPlansTableTable get dataPlansTable => attachedDatabase.dataPlansTable;
  $ExtraPacksTableTable get extraPacksTable => attachedDatabase.extraPacksTable;
  DataPlansDaoManager get managers => DataPlansDaoManager(this);
}

class DataPlansDaoManager {
  final _$DataPlansDaoMixin _db;
  DataPlansDaoManager(this._db);
  $$DataPlansTableTableTableManager get dataPlansTable =>
      $$DataPlansTableTableTableManager(
        _db.attachedDatabase,
        _db.dataPlansTable,
      );
  $$ExtraPacksTableTableTableManager get extraPacksTable =>
      $$ExtraPacksTableTableTableManager(
        _db.attachedDatabase,
        _db.extraPacksTable,
      );
}
