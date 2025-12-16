// Dart imports:
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '/core/models/editor_configs/image_generation_configs/output_formats.dart';
import '/core/models/multi_threading/thread_request_model.dart';
import '/plugins/image/src/formats/formats.dart';
import '/plugins/image/src/formats/jpeg/jpeg_chroma.dart';
import '/plugins/image/src/formats/png/png_filter.dart';
import '/plugins/image/src/image/image.dart';

/// Encodes an image into the specified format and returns the encoded data.
///
/// This function processes an [Image] object and encodes it into the
/// desired format, such as JPEG or PNG, based on the provided parameters.
/// The function supports encoding both single-frame and multi-frame images.
///
/// The encoding settings can be customized using parameters like quality,
/// chroma subsampling for JPEG, filter options for PNG, and compression
/// levels. The function returns a [Future<Uint8List>] which completes with
/// the encoded image data.
///
/// Parameters:
/// - [image]: The [Image] object to be encoded.
/// - [outputFormat]: The format to which the image should be encoded, such
///   as JPEG or PNG.
/// - [singleFrame]: Whether the image is a single frame (true) or part of
///   an animated sequence (false).
/// - [jpegQuality]: The quality level for JPEG encoding, typically a value
///   between 0 and 100.
/// - [jpegChroma]: The chroma subsampling setting for JPEG encoding.
/// - [pngFilter]: The filter type used for PNG encoding.
/// - [pngLevel]: The compression level for PNG encoding.
/// - [destroy$]: An optional [Completer<void>] to signal when to destroy
///   resources or cancel the operation.
///
/// Returns:
/// - A [Future<Uint8List>] that completes with the encoded image data as
///   a byte array.
///
/// Throws:
/// - May throw exceptions related to encoding failures or invalid parameters.

Future<Uint8List> encodeImage({
  required Image image,
  required OutputFormat outputFormat,
  required bool singleFrame,
  required int jpegQuality,
  required JpegChroma jpegChroma,
  required PngFilter pngFilter,
  required int pngLevel,
  required int jpegBackgroundColor,
  Completer<void>? destroy$,
}) async {
  final stopwatch = Stopwatch()..start();
  final imageSize = '${image.width}x${image.height}';
  Uint8List bytes;
  
  switch (outputFormat) {
    case OutputFormat.jpg:
      final encodeStopwatch = Stopwatch()..start();
      bytes = await encodeJpg(
        image,
        quality: jpegQuality,
        chroma: jpegChroma,
        destroy$: destroy$,
        backgroundColor: jpegBackgroundColor,
      );
      encodeStopwatch.stop();
      final outputSize = '${(bytes.length / 1024).toStringAsFixed(0)}KB';
      debugPrint(
        '[BENCHMARK] encodeJpg (q:$jpegQuality, chroma:$jpegChroma): ${encodeStopwatch.elapsedMilliseconds}ms (size: $imageSize, output: $outputSize)',
      );
      break;
    case OutputFormat.png:
      final encodeStopwatch = Stopwatch()..start();
      bytes = encodePng(
        image,
        filter: pngFilter,
        level: pngLevel,
        singleFrame: singleFrame,
      );
      encodeStopwatch.stop();
      final outputSize = '${(bytes.length / 1024).toStringAsFixed(0)}KB';
      debugPrint(
        '[BENCHMARK] encodePng (filter:$pngFilter, level:$pngLevel): ${encodeStopwatch.elapsedMilliseconds}ms (size: $imageSize, output: $outputSize)',
      );
      break;
    case OutputFormat.tiff:
      final encodeStopwatch = Stopwatch()..start();
      bytes = encodeTiff(image, singleFrame: singleFrame);
      encodeStopwatch.stop();
      debugPrint(
        '[BENCHMARK] encodeTiff: ${encodeStopwatch.elapsedMilliseconds}ms (size: $imageSize)',
      );
      break;
    case OutputFormat.bmp:
      final encodeStopwatch = Stopwatch()..start();
      bytes = encodeBmp(image);
      encodeStopwatch.stop();
      debugPrint(
        '[BENCHMARK] encodeBmp: ${encodeStopwatch.elapsedMilliseconds}ms (size: $imageSize)',
      );
      break;
    case OutputFormat.cur:
      final encodeStopwatch = Stopwatch()..start();
      bytes = encodeCur(image, singleFrame: singleFrame);
      encodeStopwatch.stop();
      debugPrint(
        '[BENCHMARK] encodeCur: ${encodeStopwatch.elapsedMilliseconds}ms (size: $imageSize)',
      );
      break;
    case OutputFormat.pvr:
      final encodeStopwatch = Stopwatch()..start();
      bytes = encodePvr(image, singleFrame: singleFrame);
      encodeStopwatch.stop();
      debugPrint(
        '[BENCHMARK] encodePvr: ${encodeStopwatch.elapsedMilliseconds}ms (size: $imageSize)',
      );
      break;
    case OutputFormat.tga:
      final encodeStopwatch = Stopwatch()..start();
      bytes = encodeTga(image);
      encodeStopwatch.stop();
      debugPrint(
        '[BENCHMARK] encodeTga: ${encodeStopwatch.elapsedMilliseconds}ms (size: $imageSize)',
      );
      break;
    case OutputFormat.ico:
      final encodeStopwatch = Stopwatch()..start();
      bytes = encodeIco(image, singleFrame: singleFrame);
      encodeStopwatch.stop();
      debugPrint(
        '[BENCHMARK] encodeIco: ${encodeStopwatch.elapsedMilliseconds}ms (size: $imageSize)',
      );
      break;
  }
  stopwatch.stop();
  debugPrint(
    '[BENCHMARK] encodeImage: ${stopwatch.elapsedMilliseconds}ms (format: ${outputFormat.name}, size: $imageSize)',
  );
  return bytes;
}

/// Encodes an image based on the provided [ThreadRequest].
///
/// This function takes a [ThreadRequest] object and uses its properties to
/// encode the image accordingly. The encoding process can handle different
/// output formats, JPEG quality and chroma settings, and PNG filter and level
/// settings.
///
/// Parameters:
/// - [threadRequest]: The request object containing the image and encoding
///   settings.
///
/// Returns:
/// - A [Future] that completes with the encoded image as a [Uint8List].
Future<Uint8List> encodeImageFromThreadRequest(ThreadRequest threadRequest) {
  return encodeImage(
    image: threadRequest.image,
    outputFormat: threadRequest.outputFormat,
    singleFrame: threadRequest.singleFrame,
    jpegQuality: threadRequest.jpegQuality,
    jpegChroma: threadRequest.jpegChroma,
    pngFilter: threadRequest.pngFilter,
    pngLevel: threadRequest.pngLevel,
    jpegBackgroundColor: threadRequest.jpegQuality,
  );
}
