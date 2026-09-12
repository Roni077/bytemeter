import 'package:flutter/foundation.dart';
import '../../data/models/enums.dart';

/// 3-part structured breakdown for high-typography numeric data displays.
@immutable
class DataSizeParts {
  const DataSizeParts({
    required this.first,
    required this.second,
    required this.third,
    required this.fullFormatted,
  });

  /// Integer digits portion (e.g. "12", "0").
  final String first;

  /// Decimal fractional portion including decimal point, or empty string (e.g. ".45", "").
  final String second;

  /// Unit symbol / suffix (e.g. "MB", "GB", "kB/s", "Mbps").
  final String third;

  /// Combined formatted string (e.g. "12.45 MB").
  final String fullFormatted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataSizeParts &&
          runtimeType == other.runtimeType &&
          first == other.first &&
          second == other.second &&
          third == other.third &&
          fullFormatted == other.fullFormatted;

  @override
  int get hashCode => Object.hash(first, second, third, fullFormatted);

  @override
  String toString() => fullFormatted;
}

/// High-precision data size representation supporting Decimal (1000) and Binary (1024)
/// calculations, Bits/Bytes conversion, and 3-part structured formatting.
@immutable
class DataSize implements Comparable<DataSize> {
  const DataSize(this.bytes);

  const DataSize.zero() : bytes = 0;

  factory DataSize.fromBytes(int bytes) => DataSize(bytes);

  factory DataSize.fromBits(int bits) => DataSize((bits / 8).round());

  factory DataSize.fromKB(double kb, [MetricBase base = MetricBase.decimal1000]) =>
      DataSize((kb * base.baseValue).round());

  factory DataSize.fromMB(double mb, [MetricBase base = MetricBase.decimal1000]) =>
      DataSize((mb * base.baseValue * base.baseValue).round());

  factory DataSize.fromGB(double gb, [MetricBase base = MetricBase.decimal1000]) =>
      DataSize((gb * base.baseValue * base.baseValue * base.baseValue).round());

  factory DataSize.fromTB(double tb, [MetricBase base = MetricBase.decimal1000]) =>
      DataSize((tb * base.baseValue * base.baseValue * base.baseValue * base.baseValue).round());

  /// Underlying byte representation (non-negative integer).
  final int bytes;

  /// Total bits.
  int get bits => bytes * 8;

  /// Whether the size is zero.
  bool get isZero => bytes == 0;

  /// Converts bytes to Kilobytes / Kibibytes according to the specified [base].
  double toKB([MetricBase base = MetricBase.decimal1000]) => bytes / base.baseValue;

  /// Converts bytes to Megabytes / Mebibytes according to the specified [base].
  double toMB([MetricBase base = MetricBase.decimal1000]) =>
      bytes / (base.baseValue * base.baseValue);

  /// Converts bytes to Gigabytes / Gibibytes according to the specified [base].
  double toGB([MetricBase base = MetricBase.decimal1000]) =>
      bytes / (base.baseValue * base.baseValue * base.baseValue);

  /// Converts bytes to Terabytes / Tebibytes according to the specified [base].
  double toTB([MetricBase base = MetricBase.decimal1000]) =>
      bytes / (base.baseValue * base.baseValue * base.baseValue * base.baseValue);

  static final RegExp _trailingZerosRegex = RegExp(r'\.?0+$');

  /// Formats the data size into structured [DataSizeParts] with integer, decimal, and unit components.
  DataSizeParts toParts({
    MetricBase base = MetricBase.decimal1000,
    SpeedUnitType unitType = SpeedUnitType.bytes,
    bool isRate = false,
    int decimals = 2,
    bool fixedDecimals = false,
  }) {
    if (bytes <= 0) {
      final unit = _getUnitSymbol(0, base, unitType, isRate);
      final second = fixedDecimals && decimals > 0 ? '.${'0' * decimals}' : '';
      final full = '0$second $unit';
      return DataSizeParts(first: '0', second: second, third: unit, fullFormatted: full);
    }

    final divisor = base.baseValue.toDouble();
    double value;
    int scaleIndex;

    if (unitType == SpeedUnitType.bits) {
      value = bits.toDouble();
      scaleIndex = 0;
      while (value >= divisor && scaleIndex < _bitUnits.length - 1) {
        value /= divisor;
        scaleIndex++;
      }
    } else {
      value = bytes.toDouble();
      scaleIndex = 0;
      while (value >= divisor && scaleIndex < _byteUnits(base).length - 1) {
        value /= divisor;
        scaleIndex++;
      }
    }

    final unit = _getUnitSymbol(scaleIndex, base, unitType, isRate);
    final String formattedNumber;
    if (fixedDecimals) {
      formattedNumber = value.toStringAsFixed(decimals);
    } else {
      // Trim trailing zeros after decimal point
      final fixed = value.toStringAsFixed(decimals);
      formattedNumber = fixed.contains('.')
          ? fixed.replaceAll(_trailingZerosRegex, '')
          : fixed;
    }

    final parts = formattedNumber.split('.');
    final first = parts[0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? '.${parts[1]}' : '';
    final full = '$first$second $unit';

    return DataSizeParts(
      first: first,
      second: second,
      third: unit,
      fullFormatted: full,
    );
  }

  /// Helper returning the formatted string representation.
  String format({
    MetricBase base = MetricBase.decimal1000,
    SpeedUnitType unitType = SpeedUnitType.bytes,
    bool isRate = false,
    int decimals = 2,
    bool fixedDecimals = false,
  }) {
    return toParts(
      base: base,
      unitType: unitType,
      isRate: isRate,
      decimals: decimals,
      fixedDecimals: fixedDecimals,
    ).fullFormatted;
  }

  static const List<String> _bitUnits = ['bps', 'kbps', 'Mbps', 'Gbps', 'Tbps', 'Pbps'];

  static List<String> _byteUnits(MetricBase base) {
    if (base == MetricBase.binary1024) {
      return const ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB'];
    }
    return const ['B', 'kB', 'MB', 'GB', 'TB', 'PB'];
  }

  static String _getUnitSymbol(
    int scaleIndex,
    MetricBase base,
    SpeedUnitType unitType,
    bool isRate,
  ) {
    if (unitType == SpeedUnitType.bits) {
      final safeIndex = scaleIndex.clamp(0, _bitUnits.length - 1);
      return _bitUnits[safeIndex];
    } else {
      final units = _byteUnits(base);
      final safeIndex = scaleIndex.clamp(0, units.length - 1);
      final unit = units[safeIndex];
      return isRate ? '$unit/s' : unit;
    }
  }

  // Operators
  DataSize operator +(DataSize other) => DataSize(bytes + other.bytes);
  DataSize operator -(DataSize other) => DataSize((bytes - other.bytes).clamp(0, double.maxFinite.toInt()));
  DataSize operator *(num factor) => DataSize((bytes * factor).round().clamp(0, double.maxFinite.toInt()));
  DataSize operator /(num divisor) => DataSize(divisor == 0 ? 0 : (bytes / divisor).round());

  bool operator <(DataSize other) => bytes < other.bytes;
  bool operator <=(DataSize other) => bytes <= other.bytes;
  bool operator >(DataSize other) => bytes > other.bytes;
  bool operator >=(DataSize other) => bytes >= other.bytes;

  @override
  int compareTo(DataSize other) => bytes.compareTo(other.bytes);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DataSize && runtimeType == other.runtimeType && bytes == other.bytes;

  @override
  int get hashCode => bytes.hashCode;

  @override
  String toString() => format();
}
