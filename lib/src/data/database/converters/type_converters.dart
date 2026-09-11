import 'dart:convert';
import 'package:drift/drift.dart';
import '../../models/enums.dart';

/// TypeConverter serializing a List of integer UIDs to/from a JSON string column in SQLite.
class IntListConverter extends TypeConverter<List<int>, String> {
  const IntListConverter();

  @override
  List<int> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const <int>[];
    try {
      final decoded = jsonDecode(fromDb) as List<dynamic>;
      return decoded.map((e) => (e as num).toInt()).toList(growable: false);
    } catch (_) {
      return const <int>[];
    }
  }

  @override
  String toSql(List<int> value) {
    return jsonEncode(value);
  }
}

/// TypeConverter serializing [TimeIntervalType] enum to/from String name.
class TimeIntervalTypeConverter extends TypeConverter<TimeIntervalType, String> {
  const TimeIntervalTypeConverter();

  @override
  TimeIntervalType fromSql(String fromDb) {
    return TimeIntervalType.values.firstWhere(
      (e) => e.name == fromDb,
      orElse: () => TimeIntervalType.monthly,
    );
  }

  @override
  String toSql(TimeIntervalType value) {
    return value.name;
  }
}
