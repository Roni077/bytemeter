import 'package:bytemeter/src/core/utils/data_size.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataSize Conversion & Unit Calculations', () {
    test('Zero byte representation', () {
      const zero = DataSize.zero();
      expect(zero.bytes, equals(0));
      expect(zero.bits, equals(0));
      expect(zero.isZero, isTrue);

      final parts = zero.toParts();
      expect(parts.first, equals('0'));
      expect(parts.second, equals(''));
      expect(parts.third, equals('B'));
      expect(parts.fullFormatted, equals('0 B'));
    });

    test('Decimal (1000) base scaling', () {
      final kbSize = DataSize.fromKB(2.5, MetricBase.decimal1000);
      expect(kbSize.bytes, equals(2500));
      expect(kbSize.toKB(MetricBase.decimal1000), equals(2.5));

      final mbSize = DataSize.fromMB(1.5, MetricBase.decimal1000);
      expect(mbSize.bytes, equals(1500000));
      expect(mbSize.toMB(MetricBase.decimal1000), equals(1.5));

      final gbSize = DataSize.fromGB(3.25, MetricBase.decimal1000);
      expect(gbSize.bytes, equals(3250000000));
      expect(gbSize.toGB(MetricBase.decimal1000), equals(3.25));

      final tbSize = DataSize.fromTB(1.0, MetricBase.decimal1000);
      expect(tbSize.toTB(MetricBase.decimal1000), equals(1.0));
    });

    test('Binary (1024) base scaling', () {
      final kibSize = DataSize.fromKB(1.0, MetricBase.binary1024);
      expect(kibSize.bytes, equals(1024));
      expect(kibSize.toKB(MetricBase.binary1024), equals(1.0));

      final mibSize = DataSize.fromMB(2.0, MetricBase.binary1024);
      expect(mibSize.bytes, equals(2 * 1024 * 1024));
      expect(mibSize.toMB(MetricBase.binary1024), equals(2.0));

      final gibSize = DataSize.fromGB(1.0, MetricBase.binary1024);
      expect(gibSize.bytes, equals(1024 * 1024 * 1024));
      expect(gibSize.toGB(MetricBase.binary1024), equals(1.0));
    });

    test('Bits vs Bytes conversion', () {
      final sizeFromBits = DataSize.fromBits(8000000); // 8 Mbits = 1 MByte
      expect(sizeFromBits.bytes, equals(1000000));
      expect(sizeFromBits.bits, equals(8000000));

      final bitParts = sizeFromBits.toParts(unitType: SpeedUnitType.bits);
      expect(bitParts.first, equals('8'));
      expect(bitParts.third, equals('Mbps'));
    });
  });

  group('DataSize 3-Part Formatting', () {
    test('3-part breakdown of decimal values', () {
      final size = const DataSize(12500000); // 12.5 MB decimal
      final parts = size.toParts(base: MetricBase.decimal1000);
      expect(parts.first, equals('12'));
      expect(parts.second, equals('.5'));
      expect(parts.third, equals('MB'));
      expect(parts.fullFormatted, equals('12.5 MB'));
    });

    test('3-part breakdown of whole integer values (no decimal)', () {
      final size = const DataSize(1073741824); // Exactly 1 GiB
      final parts = size.toParts(base: MetricBase.binary1024);
      expect(parts.first, equals('1'));
      expect(parts.second, equals(''));
      expect(parts.third, equals('GiB'));
      expect(parts.fullFormatted, equals('1 GiB'));
    });

    test('Transfer rate speed formatting with isRate=true', () {
      final rate = const DataSize(1500000); // 1.5 MB/s
      final byteRateParts = rate.toParts(base: MetricBase.decimal1000, isRate: true);
      expect(byteRateParts.third, equals('MB/s'));
      expect(byteRateParts.fullFormatted, equals('1.5 MB/s'));

      final bitRateParts = rate.toParts(
        base: MetricBase.decimal1000,
        unitType: SpeedUnitType.bits,
        isRate: true,
      );
      expect(bitRateParts.third, equals('Mbps'));
      expect(bitRateParts.fullFormatted, equals('12 Mbps'));
    });
  });

  group('DataSize Arithmetic & Comparison Operators', () {
    test('Addition, subtraction, multiplication, and division', () {
      const a = DataSize(500);
      const b = DataSize(300);

      expect((a + b).bytes, equals(800));
      expect((a - b).bytes, equals(200));
      expect((b - a).bytes, equals(0)); // Clamped to non-negative
      expect((a * 2).bytes, equals(1000));
      expect((a / 2).bytes, equals(250));
    });

    test('Comparisons and sorting', () {
      const small = DataSize(100);
      const medium = DataSize(500);
      const large = DataSize(1000);

      expect(small < medium, isTrue);
      expect(medium <= large, isTrue);
      expect(large > medium, isTrue);
      expect(medium >= small, isTrue);
      expect(small == const DataSize(100), isTrue);

      final list = [large, small, medium]..sort();
      expect(list, equals([small, medium, large]));
    });
  });
}
