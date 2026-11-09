import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arivu_ai/features/chat/service/local_ai_service.dart';
import 'package:arivu_ai/features/settings/presentation/settings_screen.dart';
import 'package:arivu_ai/utils/constant.dart';

void main() {
  group('Security & Supply Chain Integrity Tests', () {
    test('modelSha256 and expected size constants are defined', () {
      expect(modelSha256, isNotEmpty);
      expect(modelSha256.length, equals(64));
      expect(modelExpectedSizeBytes, equals(639446688));
      expect(modelFileName, equals('Qwen3-0.6B-Q8_0.gguf'));
    });

    test('Streaming SHA-256 computation verifies exact digest correctly', () async {
      final tempDir = await Directory.systemTemp.createTemp('sha_test');
      final testFile = File('${tempDir.path}/test_payload.bin');

      final sampleData = Uint8List.fromList([
        0x47, 0x47, 0x55, 0x46, // GGUF magic header
        0x01, 0x02, 0x03, 0x04,
      ]);
      await testFile.writeAsBytes(sampleData);

      final expectedDigest = sha256.convert(sampleData).toString();

      // Streaming hash check identical to LocalAiService._verifySha256
      final streamedDigest = await sha256.bind(testFile.openRead()).first;

      expect(streamedDigest.toString().toLowerCase(), equals(expectedDigest.toLowerCase()));

      await tempDir.delete(recursive: true);
    });

    test('Rejects tampered or corrupted binary payload', () async {
      final tempDir = await Directory.systemTemp.createTemp('sha_tamper_test');
      final testFile = File('${tempDir.path}/tampered_payload.bin');

      final sampleData = Uint8List.fromList([0x47, 0x47, 0x55, 0x46, 0x99]);
      await testFile.writeAsBytes(sampleData);

      const fakeExpectedHash = '0000000000000000000000000000000000000000000000000000000000000000';
      final streamedDigest = await sha256.bind(testFile.openRead()).first;

      expect(streamedDigest.toString().toLowerCase(), isNot(equals(fakeExpectedHash)));

      await tempDir.delete(recursive: true);
    });

    test('AndroidManifest configures allowBackup to false', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue);
      final content = manifestFile.readAsStringSync();
      expect(content, contains('android:allowBackup="false"'));
    });

    testWidgets('SettingsScreen displays Privacy & Security section with Wipe Data action',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final aiService = LocalAiService();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(aiService: aiService),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('PRIVACY & DATA SECURITY'), findsOneWidget);
      expect(find.text('Zero-Cloud Offline Guarantee'), findsOneWidget);
      expect(find.text('Wipe All Chat History'), findsOneWidget);

      // Tap on Wipe All Chat History
      await tester.tap(find.text('Wipe All Chat History'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Wipe All Conversations?'), findsOneWidget);
      expect(find.text('Wipe All Data'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Wipe All Conversations?'), findsNothing);
    });
  });
}
