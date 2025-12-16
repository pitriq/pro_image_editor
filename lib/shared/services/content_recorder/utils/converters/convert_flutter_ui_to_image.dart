import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '/plugins/image/src/image/image.dart' as img;

/// Converts a Flutter ui.Image to img.Image suitable for processing.
///
/// [uiImage] - The image to be converted.
Future<img.Image> convertFlutterUiToImage(ui.Image uiImage) async {
  final stopwatch = Stopwatch()..start();
  final imageSize = '${uiImage.width}x${uiImage.height}';
  
  final toByteDataStopwatch = Stopwatch()..start();
  final uiBytes = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
  toByteDataStopwatch.stop();
  debugPrint(
    '[BENCHMARK] convertFlutterUiToImage.toByteData: ${toByteDataStopwatch.elapsedMilliseconds}ms (size: $imageSize)',
  );

  final fromBytesStopwatch = Stopwatch()..start();
  final image = img.Image.fromBytes(
    width: uiImage.width,
    height: uiImage.height,
    bytes: uiBytes!.buffer,
    numChannels: 4,
  );
  fromBytesStopwatch.stop();
  
  stopwatch.stop();
  debugPrint(
    '[BENCHMARK] convertFlutterUiToImage.Image.fromBytes: ${fromBytesStopwatch.elapsedMilliseconds}ms',
  );
  debugPrint(
    '[BENCHMARK] convertFlutterUiToImage: ${stopwatch.elapsedMilliseconds}ms',
  );

  return image;
}
