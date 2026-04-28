import 'dart:async';

import 'package:flutter/services.dart';

/// Bridges native macOS menu actions to the Flutter layer.
///
/// Call [init] once at app start-up. Listen to [onCheckForUpdates] anywhere
/// in the widget tree to respond to the "Check for Updates…" menu item.
class AppMenuService {
  AppMenuService._();

  static final AppMenuService instance = AppMenuService._();

  static const _channel = MethodChannel('com.lumi/app_menu');

  final _checkForUpdatesController = StreamController<void>.broadcast();

  /// Emits whenever the user chooses "Check for Updates…" from the app menu.
  Stream<void> get onCheckForUpdates => _checkForUpdatesController.stream;

  void init() {
    _channel.setMethodCallHandler((call) async {
      try {
        if (call.method == 'checkForUpdates') {
          if (!_checkForUpdatesController.isClosed) {
            _checkForUpdatesController.add(null);
          }
        }
      } catch (e) {
        print('AppMenuService: error handling method call ${call.method}: $e');
      }
    });
  }

  void dispose() {
    _checkForUpdatesController.close();
  }
}
