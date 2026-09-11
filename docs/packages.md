# ByteMeter: Dependencies & Packages Specification

This document details all third-party dependencies, version constraints, technical rationale, and setup requirements for **ByteMeter**.

---

## 🎯 Verification & Build Protocol

> [!IMPORTANT]
> - **Static Analysis Verification**: Run `flutter analyze` immediately upon completing each phase. A phase is ONLY considered complete when `flutter analyze` returns with **0 issues found**.
> - **Strictly No APK Builds**: NEVER run `flutter build apk` during execution to avoid long compilation times. Rely strictly on `flutter analyze` and fast unit/widget tests (`flutter test`).
> - **Graphify Visuals**: All package relationships and code-generation pipelines are mapped with Graphify / Mermaid diagrams.

---

## Dependency Overview

```mermaid
graph TD
    subgraph Core Framework
        FlutterSDK[Flutter SDK ^3.13.0]
    end

    subgraph State Management & Architecture
        Riverpod[flutter_riverpod: ^2.6.1]
    end

    subgraph Local Database & Persistence
        Drift[drift: ^2.24.2]
        SqliteLibs[sqlite3_flutter_libs: ^0.5.28]
        PathProvider[path_provider: ^2.1.5]
        SharedPrefs[shared_preferences: ^2.3.5]
    end

    subgraph Design, Theming & UI
        DynamicColor[dynamic_color: ^1.7.0]
        GoogleFonts[google_fonts: ^6.2.1]
        Intl[intl: ^0.20.2]
        CupertinoIcons[cupertino_icons: ^1.0.8]
    end

    subgraph Dev & Code Generation
        DriftDev[drift_dev: ^2.24.2]
        BuildRunner[build_runner: ^2.4.15]
        FlutterLints[flutter_lints: ^6.0.0]
    end

    FlutterSDK --> Riverpod
    FlutterSDK --> Drift
    FlutterSDK --> DynamicColor
    Drift --> SqliteLibs
    Drift --> PathProvider
    DriftDev --> BuildRunner
```

---

## Runtime Dependencies (`dependencies`)

### 1. `flutter_riverpod: ^2.6.1`
- **Purpose**: Declarative, unidirectional state management and dependency injection.
- **Why Chosen**:
  - Eliminates context-dependency for business logic.
  - Native support for asynchronous data streams (`StreamProvider` for real-time speed stream and `FutureProvider` for daily/monthly historical usage queries).
  - Clean separation of UI widgets from repository queries and native platform channel bridges.
- **Usage**:
  - `speedStreamProvider`: Subscribes to live 1-second transfer rate ticks from the native Android `EventChannel`.
  - `overviewControllerProvider`: Manages today's usage, prediction math, trend calculation, and top apps.
  - `historyControllerProvider`: Manages 90-day timeline cache, date filters, and dual comparison queries.
  - `dataPlansControllerProvider`: Manages multi-SIM configuration, quota budgets, and extra packs.

---

### 2. `drift: ^2.24.2` & `sqlite3_flutter_libs: ^0.5.28`
- **Purpose**: Type-safe, high-performance relational SQLite database.
- **Why Chosen**:
  - Native SQLite backing on Android without heavy runtime overhead.
  - Compile-time SQL verification and type-safe Dart queries.
  - Built-in reactive query streams (`watch()`) for instant UI updates when data plans or extra packs change.
- **Tables Defined**:
  - `DataPlansTable`: Stores SIM slot index, hashed subscriber ID, encrypted subscriber ID, quota bytes, interval (Month/Day), rollover flag, and JSON list of excluded apps.
  - `ExtraPacksTable`: Stores addon data packs (+X GB valid until date Y) linked to individual data plans.
- **Complementary Library**:
  - `path_provider: ^2.1.5`: Locates the internal app data directory for SQLite database storage.

---

### 3. `shared_preferences: ^2.3.5`
- **Purpose**: Fast, persistent key-value storage for app settings and preferences.
- **Keys Managed**:
  - `speed_unit_bits`: Boolean (Bits/s vs. Bytes/s)
  - `metric_base_1000`: Boolean (Decimal 1000 base vs. Binary 1024 base)
  - `theme_mode`: String (`auto`, `light`, `dark`, `amoled`)
  - `enable_blur`: Boolean (Frosted glass backdrop filter)
  - `persistent_notification_enabled`: Boolean (Master speed notification switch)
  - `notification_icon_style`: String (`combined`, `separate_up_down`)
  - `silent_speed_threshold_kb`: Integer (Auto-hide speed threshold in KB/s)
  - `aod_mode_enabled`: Boolean (Continue updating on Always-On-Display / Screen off)
  - `overview_default_type`: String (`mobile`, `wifi`)

---

### 4. `dynamic_color: ^1.7.0`
- **Purpose**: Material You Android 12+ dynamic color scheme extraction.
- **Why Chosen**:
  - Extracts the dominant user wallpaper palette on Android devices running API 31+.
  - Harmonizes custom app colors with system color accents for a truly native Android feel.
  - Falls back gracefully to the standard ByteMeter expressive color palette on older Android versions and non-supported devices.

---

### 5. `google_fonts: ^6.2.1`
- **Purpose**: Expressive typography matching the reference app's Google Sans styling.
- **Why Chosen**:
  - Provides variable font weights (Light, Regular, Medium, SemiBold, Bold, ExtraBold) and rounded styling for large numeric speed meters and usage displays.

---

### 6. `intl: ^0.20.2`
- **Purpose**: Date, time, and numeric formatting.
- **Usage**:
  - Localized 2-hour interval time bucket strings (e.g. `12:00 AM - 02:00 AM`).
  - Localized month and day names for the 90-day scrollable history timeline.

---

## Development Dependencies (`dev_dependencies`)

| Package | Version | Purpose |
|---|---|---|
| **`drift_dev`** | `^2.24.2` | Code generator for Drift database tables, DAOs, and type-safe query builders |
| **`build_runner`** | `^2.4.15` | CLI code generator orchestrator |
| **`flutter_lints`** | `^6.0.0` | Recommended static analysis and code quality lint rules |
| **`flutter_test`** | `sdk: flutter` | Unit testing and widget smoke testing framework |

---

## Sample `pubspec.yaml` Specification

```yaml
name: bytemeter
description: "A fast, privacy-focused network speed meter and data usage monitor."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.13.0

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.6.1

  # Database & Persistence
  drift: ^2.24.2
  sqlite3_flutter_libs: ^0.5.28
  path_provider: ^2.1.5
  shared_preferences: ^2.3.5

  # Design & Theming
  dynamic_color: ^1.7.0
  google_fonts: ^6.2.1
  intl: ^0.20.2
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  drift_dev: ^2.24.2
  build_runner: ^2.4.15

flutter:
  uses-material-design: true

  assets:
    - assets/icons/
    - assets/fonts/
```
