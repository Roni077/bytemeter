# ByteMeter Engineering Guidelines & Project Rules

This document defines the strict engineering guidelines and architecture rules for developing **ByteMeter**.

---

## 1. Architecture & Design Rules
- **MVVM Pattern**: Declarative Views (`lib/src/features/*/widgets/`) observe ViewModels (`lib/src/features/*/*_controller.dart`) via Riverpod (`ref.watch()`).
- **Separation of Concerns**: Never place database queries, network stats calls, or mathematical algorithms inside widget `build()` methods.
- **State Immutability**: All states must be immutable data classes with `copyWith()` methods.
- **Repositories**: ViewModels only interact with Repositories (`lib/src/data/repositories/`), which act as the single source of truth.

---

## 2. Formatting & Units
- **DataSize Utility**: Always use `DataSize` (`lib/src/core/utils/data_size.dart`) for converting and formatting byte values into Decimal (1000) or Binary (1024) units.
- **3-Part Formatting**: For large numeric displays, format numbers into `first` (integer part), `second` (decimal part), and `third` (unit label).

---

## 3. UI, Graphics & Performance
- **CustomPainter**: Use `CustomPainter` for complex canvas graphics (`HeroGeometricGauge`, `WeeklyBarChart`, `ScrollableBarChart`, `ComparativeLineChart`, `AppUsageBarChart`).
- **Dynamic Text Fitting**: In horizontal app usage bars, use binary-search text width measurement with `TextPainter` to avoid text clipping.
- **Const Constructors**: Use `const` constructors wherever possible for optimal Flutter rendering performance.

---

## 4. Native Android & Battery Efficiency
- **Foreground Service**: Android speed meter runs inside `ByteMeterForegroundService` using `PROPERTY_SPECIAL_USE_FGS_SUBTYPE`.
- **Zero Battery Idle**: Always pause speed polling when the screen locks (`ACTION_SCREEN_OFF`) unless AOD mode is explicitly enabled by the user.
- **Dynamic Status Bar Icon**: Render live speed numbers onto in-memory `Bitmap` with Android `Canvas` and assign as notification `smallIcon`.

---

## 5. Verification, Build & Documentation Protocol
- **Analyze After Each Phase**: Run `flutter analyze` immediately after completing every phase to ensure 0 lint errors, 0 warnings, and clean static analysis.
- **Strictly No APK Builds**: NEVER run `flutter build apk` during execution to prevent heavy compilation timeouts; verify strictly via `flutter analyze` and `flutter test`.
- **Graphify / Mermaid Diagrams**: Always use visual Mermaid / Graphify architecture and data-flow diagrams for documenting phase structures and component relationships across all documentation and implementation plans.

