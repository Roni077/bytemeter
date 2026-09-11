/// Special Android system and aggregated UIDs used in network traffic accounting.
class SpecialUids {
  const SpecialUids._();

  /// Virtual UID representing all applications aggregated.
  static const int uidAll = -100;

  /// Virtual UID representing unknown or unclassified background services.
  static const int uidUnknown = -99;

  /// Virtual UID representing other user accounts or Secure Folder.
  static const int uidOtherUsers = -98;

  /// Android system UID for Wi-Fi/Bluetooth hotspot and USB tethering.
  static const int uidTethering = -5;

  /// Android system UID for apps that have been uninstalled during the current cycle.
  static const int uidRemoved = -4;

  /// Set of all predefined special UIDs.
  static const List<int> specialUids = [
    uidAll,
    uidUnknown,
    uidOtherUsers,
    uidTethering,
    uidRemoved,
  ];

  /// Returns `true` if the given UID is one of the special/virtual system UIDs.
  static bool isSpecial(int uid) => uid < 0;
}
