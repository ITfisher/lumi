import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ClipboardImageService {
  static const MethodChannel _channel = MethodChannel(
    'com.lumi/clipboard_image',
  );

  static Future<String?> persistClipboardImage() async {
    if (kIsWeb) return null;

    try {
      final bytes = await _channel.invokeMethod<Uint8List>('readImageBytes');
      if (bytes == null || bytes.isEmpty) return null;

      final imageDirectory = await _imageDirectory();
      if (!await imageDirectory.exists()) {
        await imageDirectory.create(recursive: true);
      }

      final file = File(
        path.join(
          imageDirectory.path,
          'clipboard_${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static Future<Directory> _imageDirectory() async {
    try {
      final libraryDirectory = await getLibraryDirectory();
      return Directory(path.join(libraryDirectory.path, 'lumi_pasted_images'));
    } catch (_) {
      final tempDirectory = await getTemporaryDirectory();
      return Directory(path.join(tempDirectory.path, 'lumi_pasted_images'));
    }
  }
}
