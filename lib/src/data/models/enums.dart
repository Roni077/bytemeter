/// Network interface types monitored by ByteMeter.
enum NetworkType {
  mobile(0, 'Mobile'),
  wifi(1, 'Wi-Fi');

  const NetworkType(this.typeIndex, this.displayName);

  final int typeIndex;
  final String displayName;
}

/// Traffic direction filter for statistics queries.
enum DataDirection {
  upload('Upload'),
  download('Download'),
  bidirectional('Bidirectional');

  const DataDirection(this.displayName);

  final String displayName;
}

/// Recurring time interval for data plan quota calculations.
enum TimeIntervalType {
  daily('Daily'),
  monthly('Monthly'),
  custom('Custom');

  const TimeIntervalType(this.displayName);

  final String displayName;
}

/// Dynamic Data Plan safety health indicator.
enum DataSafetyState {
  safe('Safe'),
  neutral('Neutral'),
  unsafe('Unsafe');

  const DataSafetyState(this.displayName);

  final String displayName;
}

/// User selectable UI theme appearance.
enum ThemeModePreference {
  auto('Auto Material'),
  light('Light Material'),
  dark('Dark Material'),
  amoled('AMOLED Pitch Black');

  const ThemeModePreference(this.displayName);

  final String displayName;
}

/// Status bar notification speed icon visual format.
enum NotificationIconStyle {
  combined('Combined Speed'),
  separateUpDown('Separate Up / Down');

  const NotificationIconStyle(this.displayName);

  final String displayName;
}

/// Speed unit formatting representation (Bytes vs Bits).
enum SpeedUnitType {
  bytes('Bytes (MB/s)'),
  bits('Bits (Mbps)');

  const SpeedUnitType(this.displayName);

  final String displayName;
}

/// Magnitude calculation base (Decimal 1000 vs Binary 1024).
enum MetricBase {
  decimal1000(1000, 'Decimal (1000)'),
  binary1024(1024, 'Binary (1024)');

  const MetricBase(this.baseValue, this.displayName);

  final int baseValue;
  final String displayName;
}
