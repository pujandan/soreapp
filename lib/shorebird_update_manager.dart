import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class ShorebirdUpdateManager {
  final _updater = ShorebirdUpdater();

  // Status update
  final ValueNotifier<UpdateStatus> updateStatus = ValueNotifier(
    UpdateStatus.upToDate,
  );

  // Progress download (0.0 - 1.0)
  final ValueNotifier<double> downloadProgress = ValueNotifier(0.0);

  // Download state
  final ValueNotifier<bool> isDownloading = ValueNotifier(false);

  /// Check dan auto-download update
  Future<bool> checkAndDownloadUpdate({
    VoidCallback? onUpdateReady,
    VoidCallback? onNoUpdate,
    Function(String)? onError,
  }) async {
    try {
      debugPrint('🔍 Checking for updates...');

      isDownloading.value = true;

      // Check update available
      final status = await _updater.checkForUpdate();

      updateStatus.value = status;

      if (status == UpdateStatus.upToDate) {
        debugPrint('✅ App is up to date');
        isDownloading.value = false;
        onNoUpdate?.call();
        return false;
      }

      if (status == UpdateStatus.outdated) {
        debugPrint('📦 Update available! Downloading...');

        // Simulate progress
        _simulateDownloadProgress();

        try {
          // Download update
          await _updater.update();

          downloadProgress.value = 1.0;
          isDownloading.value = false;

          debugPrint('✅ Update downloaded successfully!');

          // Callback untuk notify UI
          onUpdateReady?.call();

          return true;
        } on UpdateException catch (e) {
          debugPrint('❌ Update failed: $e');
          isDownloading.value = false;
          onError?.call(e.toString());
          return false;
        }
      }

      isDownloading.value = false;
      return false;
    } catch (e) {
      debugPrint('❌ Error during update check: $e');
      isDownloading.value = false;
      onError?.call(e.toString());
      return false;
    }
  }

  /// Simulate download progress
  void _simulateDownloadProgress() async {
    downloadProgress.value = 0.0;
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(Duration(milliseconds: 100));
      if (isDownloading.value) {
        downloadProgress.value = i / 100;
      }
    }
  }

  /// Get current patch info
  Future<PatchInfo?> getCurrentPatchInfo() async {
    try {
      final patch = await _updater.readCurrentPatch();

      if (patch != null) {
        return PatchInfo(
          patchNumber: patch.number,
          patchVersion: patch.number.toString(),
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error getting patch info: $e');
      return null;
    }
  }

  /// Restart app (force close)
  void restartApp() {
    SystemNavigator.pop();
  }

  /// Check for update with custom track
  Future<bool> checkAndDownloadUpdateWithTrack({
    required UpdateTrack track,
    VoidCallback? onUpdateReady,
    VoidCallback? onNoUpdate,
    Function(String)? onError,
  }) async {
    try {
      debugPrint('🔍 Checking for updates on track: ${track.value}...');

      isDownloading.value = true;

      final status = await _updater.checkForUpdate(track: track);

      updateStatus.value = status;

      if (status == UpdateStatus.outdated) {
        debugPrint(
          '📦 Update available on track ${track.value}! Downloading...',
        );

        _simulateDownloadProgress();

        try {
          await _updater.update(track: track);

          downloadProgress.value = 1.0;
          isDownloading.value = false;

          debugPrint('✅ Update downloaded successfully!');

          onUpdateReady?.call();

          return true;
        } on UpdateException catch (e) {
          debugPrint('❌ Update failed: $e');
          isDownloading.value = false;
          onError?.call(e.toString());
          return false;
        }
      }

      isDownloading.value = false;
      onNoUpdate?.call();
      return false;
    } catch (e) {
      debugPrint('❌ Error during update check: $e');
      isDownloading.value = false;
      onError?.call(e.toString());
      return false;
    }
  }

  /// Dispose all notifiers
  void dispose() {
    updateStatus.dispose();
    downloadProgress.dispose();
    isDownloading.dispose();
  }
}

/// Model patch info
class PatchInfo {
  final int patchNumber;
  final String patchVersion;

  PatchInfo({required this.patchNumber, required this.patchVersion});

  @override
  String toString() => 'Patch #$patchNumber';
}
