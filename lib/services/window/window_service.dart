import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// Centralized window and fullscreen state manager for desktop and mobile.
class WindowService with WindowListener {
  static final WindowService instance = WindowService._internal();
  WindowService._internal();

  final ValueNotifier<bool> isFullscreenNotifier = ValueNotifier<bool>(false);
  bool _isTransitioning = false;

  bool get isFullscreen => isFullscreenNotifier.value;
  bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  Future<void> initialize() async {
    if (!isDesktop) return;
    try {
      windowManager.addListener(this);
      final isFs = await windowManager.isFullScreen();
      isFullscreenNotifier.value = isFs;
    } catch (e) {
      debugPrint('[WindowService] initialize error: $e');
    }
  }

  void dispose() {
    if (isDesktop) {
      windowManager.removeListener(this);
    }
  }

  /// Executes true borderless OS fullscreen toggle covering the Windows taskbar.
  Future<void> toggleFullscreen() async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    try {
      if (!isDesktop) {
        // Mobile fallback
        final next = !isFullscreenNotifier.value;
        isFullscreenNotifier.value = next;
        if (next) {
          await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        } else {
          await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        }
        return;
      }

      final isCurrentlyFs = await windowManager.isFullScreen();
      if (isCurrentlyFs || isFullscreenNotifier.value) {
        await windowManager.setFullScreen(false);
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        }
        isFullscreenNotifier.value = false;
      } else {
        // Crucial for Windows: unmaximize first to drop the 8px DWM resize frame
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        }
        await windowManager.setFullScreen(true);
        isFullscreenNotifier.value = true;
      }
    } catch (e) {
      debugPrint('[WindowService] toggleFullscreen error: $e');
    } finally {
      _isTransitioning = false;
    }
  }

  /// Alias for toggleFullscreen
  Future<void> toggleFullScreen() => toggleFullscreen();

  /// Forces exit from fullscreen (e.g. when leaving player screen).
  Future<void> exitFullscreen() async {
    if (!isDesktop) {
      if (isFullscreenNotifier.value) {
        isFullscreenNotifier.value = false;
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
      return;
    }
    if (_isTransitioning) return;
    _isTransitioning = true;
    try {
      final isCurrentlyFs = await windowManager.isFullScreen();
      if (isCurrentlyFs || isFullscreenNotifier.value) {
        await windowManager.setFullScreen(false);
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        }
        isFullscreenNotifier.value = false;
      }
    } catch (e) {
      debugPrint('[WindowService] exitFullscreen error: $e');
    } finally {
      _isTransitioning = false;
    }
  }

  // ── WindowListener Callbacks (Synchronize OS events) ──

  @override
  void onWindowEnterFullScreen() {
    isFullscreenNotifier.value = true;
  }

  @override
  void onWindowLeaveFullScreen() {
    isFullscreenNotifier.value = false;
  }

  @override
  void onWindowRestore() {
    windowManager.isFullScreen().then((isFs) {
      isFullscreenNotifier.value = isFs;
    });
  }

  @override
  void onWindowUnmaximize() {
    windowManager.isFullScreen().then((isFs) {
      isFullscreenNotifier.value = isFs;
    });
  }

  @override
  void onWindowMaximize() {
    windowManager.isFullScreen().then((isFs) {
      isFullscreenNotifier.value = isFs;
    });
  }
}
