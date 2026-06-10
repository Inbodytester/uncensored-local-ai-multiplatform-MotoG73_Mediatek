import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'chat_storage_service.dart';

/// Keeps downloads, model loading, and AI inference alive when the screen locks.
///
/// Uses an Android foreground service (CPU wake lock, no screen-on required).
/// Optional screen wake lock is available in Settings for users who want it.
class WakelockService extends GetxService {
  final isWakeLockActive = false.obs;
  final isForegroundServiceActive = false.obs;

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  ChatStorageService? get _storage {
    try {
      return Get.find<ChatStorageService>();
    } catch (_) {
      return null;
    }
  }

  bool get _runWhenScreenLocked =>
      _storage?.runWhenScreenLocked ?? true;

  bool get _keepScreenOn => _storage?.keepScreenOnDuringAi ?? false;

  Future<WakelockService> init() async {
    if (_isMobile) {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'portable_ai_foreground',
          channelName: 'Uncensored Local AI',
          channelDescription:
              'Keeps downloads and AI inference running when the screen is off',
          channelImportance: NotificationChannelImportance.DEFAULT,
          priority: NotificationPriority.DEFAULT,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
          autoRunOnBoot: false,
          autoRunOnMyPackageReplaced: false,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );

      await FlutterForegroundTask.requestNotificationPermission();
    }
    return this;
  }

  /// Re-assert background execution when the app moves to the background.
  Future<void> onAppPaused({
    required bool modelLoaded,
    required bool isGenerating,
    required bool isLoadingModel,
    String modelName = 'AI model',
  }) async {
    if (!_isMobile || !_runWhenScreenLocked) return;

    if (isGenerating) {
      await enableForGeneration(modelName: modelName);
    } else if (isLoadingModel) {
      await enableForModelLoad(modelName: modelName);
    } else if (modelLoaded) {
      await enableForInference(modelName: modelName);
    }
  }

  Future<void> _maybeEnableScreenWakeLock() async {
    if (!_keepScreenOn) return;
    try {
      await WakelockPlus.enable();
      isWakeLockActive.value = true;
    } catch (e) {
      debugPrint('WakelockService screen wake lock error: $e');
    }
  }

  Future<void> _maybeDisableScreenWakeLock() async {
    if (!_keepScreenOn) return;
    try {
      await WakelockPlus.disable();
      isWakeLockActive.value = false;
    } catch (_) {}
  }

  Future<void> _startOrUpdateService({
    required String title,
    required String text,
    required int serviceId,
  }) async {
    if (!_isMobile || !_runWhenScreenLocked) return;

    try {
      await _maybeEnableScreenWakeLock();

      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
        );
      } else {
        await FlutterForegroundTask.startService(
          notificationTitle: title,
          notificationText: text,
          serviceId: serviceId,
        );
      }
      isForegroundServiceActive.value = true;
    } catch (e) {
      debugPrint('WakelockService foreground service error: $e');
    }
  }

  /// Enable background execution for model download.
  Future<void> enableForDownload({String modelName = 'model'}) async {
    await _startOrUpdateService(
      title: 'Downloading $modelName',
      text: 'Continues when the screen is locked',
      serviceId: 100,
    );
  }

  /// Update the foreground notification with download progress.
  Future<void> updateDownloadProgress({
    required String modelName,
    required double progress,
    String? speedText,
  }) async {
    if (!_isMobile || !_runWhenScreenLocked) return;

    try {
      final pct = (progress * 100).toInt();
      final speed = speedText != null ? ' • $speedText' : '';
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Downloading $modelName — $pct%',
        notificationText: 'Continues when the screen is locked$speed',
      );
    } catch (_) {}
  }

  /// Keep model loading alive when the screen locks.
  Future<void> enableForModelLoad({String modelName = 'model'}) async {
    await _startOrUpdateService(
      title: 'Loading $modelName',
      text: 'Model load continues when the screen is locked',
      serviceId: 102,
    );
  }

  /// Keep a loaded model alive when the screen locks.
  Future<void> enableForInference({String modelName = 'AI model'}) async {
    await _startOrUpdateService(
      title: 'AI Model Active',
      text: '$modelName is ready — runs when the screen is locked',
      serviceId: 101,
    );
  }

  /// Keep response generation alive when the screen locks.
  Future<void> enableForGeneration({String modelName = 'AI model'}) async {
    await _startOrUpdateService(
      title: 'Generating response',
      text: '$modelName is thinking — safe to lock the screen',
      serviceId: 103,
    );
  }

  /// Return to idle inference notification after generation completes.
  Future<void> finishGeneration({String modelName = 'AI model'}) async {
    await enableForInference(modelName: modelName);
  }

  /// Disable wake lock and stop foreground service.
  Future<void> disable() async {
    if (!_isMobile) return;

    await _maybeDisableScreenWakeLock();

    try {
      await FlutterForegroundTask.stopService();
      isForegroundServiceActive.value = false;
    } catch (_) {}
  }

  @override
  void onClose() {
    disable();
    super.onClose();
  }
}