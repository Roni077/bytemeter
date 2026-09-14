import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bytemeter/src/core/constants/special_uids.dart';
import 'package:bytemeter/src/core/native/native_traffic_bridge.dart';
import 'package:bytemeter/src/core/providers/core_providers.dart';
import 'package:bytemeter/src/core/widgets/app_icon_avatar.dart';
import 'package:bytemeter/src/data/models/app_info.dart';
import 'package:bytemeter/src/data/repositories/network_usage_repository.dart';

class MockNativeTrafficBridge extends Fake implements NativeTrafficBridge {
  final Map<String, Uint8List?> iconResponses = {};

  @override
  Future<Uint8List?> getAppIcon(String packageName) async {
    return iconResponses[packageName];
  }

  @override
  Future<List<AppInfo>> getInstalledApps() async => [];
}

// 1x1 transparent PNG byte array
final Uint8List testPngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNativeTrafficBridge mockBridge;
  late NetworkUsageRepository usageRepo;

  setUp(() {
    mockBridge = MockNativeTrafficBridge();
    usageRepo = NetworkUsageRepository(bridge: mockBridge);
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        networkUsageRepositoryProvider.overrideWithValue(usageRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Center(child: child),
        ),
      ),
    );
  }

  group('AppIconAvatar Widget Tests', () {
    testWidgets('Renders special icons immediately for special UIDs', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppIconAvatar.fromAppInfo(
            app: const AppInfo(
              uid: SpecialUids.uidTethering,
              packageName: 'system.tethering',
              label: 'Tethering',
              isSpecial: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_tethering_rounded), findsOneWidget);
    });

    testWidgets('Renders removed apps icon for SpecialUids.uidRemoved', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppIconAvatar.fromAppInfo(
            app: const AppInfo(
              uid: SpecialUids.uidRemoved,
              packageName: 'system.removed_apps',
              label: 'Removed Apps',
              isSpecial: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_sweep_rounded), findsOneWidget);
    });

    testWidgets('Renders other users icon for SpecialUids.uidOtherUsers', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppIconAvatar.fromAppInfo(
            app: const AppInfo(
              uid: SpecialUids.uidOtherUsers,
              packageName: 'system.other_users',
              label: 'Other Users',
              isSpecial: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.devices_other_rounded), findsOneWidget);
    });

    testWidgets('Renders Image.memory immediately when iconBytes is provided', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppIconAvatar.fromAppInfo(
            app: AppInfo(
              uid: 10001,
              packageName: 'com.whatsapp',
              label: 'WhatsApp',
              iconBytes: testPngBytes,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('Lazily loads icon from repository in background', (tester) async {
      mockBridge.iconResponses['com.whatsapp'] = testPngBytes;

      await tester.pumpWidget(
        buildTestableWidget(
          AppIconAvatar.fromAppInfo(
            app: const AppInfo(
              uid: 10001,
              packageName: 'com.whatsapp',
              label: 'WhatsApp',
            ),
          ),
        ),
      );

      // Initially, shows fallback icon while fetching
      expect(find.byIcon(Icons.android_rounded), findsOneWidget);

      // Settle background future and frame callback
      await tester.pumpAndSettle();

      // Now it displays Image.memory
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('Falls back to default icon when bridge returns null', (tester) async {
      mockBridge.iconResponses['com.unknown'] = null;

      await tester.pumpWidget(
        buildTestableWidget(
          AppIconAvatar.fromAppInfo(
            app: const AppInfo(
              uid: 10099,
              packageName: 'com.unknown',
              label: 'Unknown App',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.android_rounded), findsOneWidget);
    });
  });
}
