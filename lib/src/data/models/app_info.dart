import 'package:flutter/foundation.dart';

/// Metadata describing an installed application or special system attribution target.
@immutable
class AppInfo {
  const AppInfo({
    required this.uid,
    required this.packageName,
    required this.label,
    this.iconBytes,
    this.isSpecial = false,
  });

  /// Deserializes a map received from native app inspection queries.
  factory AppInfo.fromMap(Map<dynamic, dynamic> map) {
    final uid = (map['uid'] as num?)?.toInt() ?? -99;
    final packageName = map['packageName'] as String? ?? '';
    final label = map['label'] as String? ?? (packageName.isNotEmpty ? packageName : 'Unknown');
    final rawBytes = map['iconBytes'];
    final iconBytes = rawBytes is Uint8List
        ? rawBytes
        : rawBytes is List<dynamic>
            ? Uint8List.fromList(rawBytes.cast<int>())
            : null;
    final isSpecial = map['isSpecial'] as bool? ?? (uid < 0);

    return AppInfo(
      uid: uid,
      packageName: packageName,
      label: label,
      iconBytes: iconBytes,
      isSpecial: isSpecial,
    );
  }

  final int uid;
  final String packageName;
  final String label;
  final Uint8List? iconBytes;
  final bool isSpecial;

  AppInfo copyWith({
    int? uid,
    String? packageName,
    String? label,
    Uint8List? iconBytes,
    bool? isSpecial,
  }) {
    return AppInfo(
      uid: uid ?? this.uid,
      packageName: packageName ?? this.packageName,
      label: label ?? this.label,
      iconBytes: iconBytes ?? this.iconBytes,
      isSpecial: isSpecial ?? this.isSpecial,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'packageName': packageName,
      'label': label,
      'iconBytes': iconBytes,
      'isSpecial': isSpecial,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppInfo &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          packageName == other.packageName &&
          label == other.label &&
          isSpecial == other.isSpecial;

  @override
  int get hashCode => Object.hash(uid, packageName, label, isSpecial);

  @override
  String toString() => 'AppInfo(uid: $uid, package: $packageName, label: $label, special: $isSpecial)';
}
