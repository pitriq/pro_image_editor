import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '/core/models/editor_configs/image_generation_configs/image_generation_configs.dart';
import '/core/models/multi_threading/thread_request_model.dart';
import '../utils/converters/convert_flutter_ui_to_image.dart';
import '../utils/dart_ui_remove_transparent_image_areas.dart';
import '../utils/encoder/encode_image.dart';
import 'thread_manager.dart';

/// A service class responsible for converting images based on the provided
/// configurations and managing the conversion process using a thread manager.
///
/// The [ImageConverterService] class requires an instance of
/// [ImageGenerationConfigs] and [ThreadManager] to be provided during
/// initialization.
///
/// Properties:
/// - `configs`: An instance of [ImageGenerationConfigs] that holds the
///   configuration settings for image generation.
/// - `threadManager`: An instance of [ThreadManager] that manages the
///   threading for the image conversion process.
class ImageConverterService {
  /// Creates an `ImageConverterService` instance to handle image conversion
  /// tasks.
  const ImageConverterService({
    required this.configs,
    required this.threadManager,
  });

  /// Configuration settings for image generation and processing.
  ///
  /// This includes parameters like output format, compression quality, and
  /// other options that dictate how images should be processed and converted.
  final ImageGenerationConfigs configs;

  /// Manages threading operations for the image conversion process.
  ///
  /// Responsible for coordinating tasks across multiple threads or isolates,
  /// ensuring efficient offloading of image processing tasks when supported.
  final ThreadManager threadManager;

  /// Converts a given `ui.Image` into a `Uint8List` representation, suitable
  /// for storage or further processing. The method determines whether to
  /// process the image on the main thread or in a separate thread based on the
  /// configuration and platform support.
  ///
  /// If multi-threading is enabled and supported, the image is processed in a
  /// separate thread for better performance. If an error occurs or
  /// multi-threading is not supported, the method gracefully falls back to
  /// processing the image on the main thread.
  ///
  /// - [image]: The `ui.Image` to be converted.
  /// - [id]: A unique identifier for the conversion task.
  /// - [format]: The output format of the image. Defaults to the format defined
  ///   in the `configs` if not provided.
  ///
  /// Returns a `Uint8List` containing the converted image data or `null` if
  /// the conversion fails.
  Future<Uint8List?> convert({
    required ui.Image image,
    required String id,
    OutputFormat? format,
  }) async {
    final stopwatch = Stopwatch()..start();
    format ??= configs.outputFormat;
    final imageSize = '${image.width}x${image.height}';

    if (configs.enableIsolateGeneration) {
      try {
        /// For the case multithreading isn't supported we fall back to the
        /// main thread.
        if (!threadManager.isSupported) {
          debugPrint('[BENCHMARK] convert: using main thread (isolate not supported)');
          return await _convertOnMainThread(image: image);
        }

        debugPrint('[BENCHMARK] convert: using isolate thread');
        final result = await threadManager.send(
          await _generateSendImageData(
            id: id,
            image: image,
            format: format,
          ),
        );
        stopwatch.stop();
        debugPrint(
          '[BENCHMARK] convert (isolate): ${stopwatch.elapsedMilliseconds}ms (size: $imageSize, format: ${format.name})',
        );
        return result;
      } catch (e) {
        // Fallback to the main thread.
        debugPrint('Fallback to main thread: $e');
        return await _convertOnMainThread(image: image);
      }
    } else {
      debugPrint('[BENCHMARK] convert: using main thread (isolate disabled)');
      return await _convertOnMainThread(image: image);
    }
  }

  /// Processes the given `ui.Image` on the main thread according to the
  /// configuration settings. If the configuration requires capturing only the
  /// visible content (drawing bounds), the transparent areas of the image are
  /// removed before encoding.
  ///
  /// - [image]: The `ui.Image` to process.
  ///
  /// Returns a `Uint8List` containing the converted image data or `null`
  /// if the conversion fails.
  Future<Uint8List?> _convertOnMainThread({
    required ui.Image image,
  }) async {
    final stopwatch = Stopwatch()..start();
    final imageSize = '${image.width}x${image.height}';
    
    if (configs.cropToDrawingBounds) {
      final cropStopwatch = Stopwatch()..start();
      image = await dartUiRemoveTransparentImgAreas(image) ?? image;
      cropStopwatch.stop();
      debugPrint(
        '[BENCHMARK] _convertOnMainThread.crop: ${cropStopwatch.elapsedMilliseconds}ms',
      );
    }
    
    final convertStopwatch = Stopwatch()..start();
    final convertedImage = await convertFlutterUiToImage(image);
    convertStopwatch.stop();
    debugPrint(
      '[BENCHMARK] _convertOnMainThread.convertFlutterUiToImage: ${convertStopwatch.elapsedMilliseconds}ms',
    );
    
    final encodeStopwatch = Stopwatch()..start();
    final result = await encodeImageFromThreadRequest(
      ThreadRequest(
        id: 'id',
        image: convertedImage,
        outputFormat: configs.outputFormat,
        singleFrame: configs.singleFrame,
        jpegQuality: configs.jpegQuality,
        jpegBackgroundColor: configs.jpegBackgroundColor.toARGB32(),
        jpegChroma: configs.jpegChroma,
        pngFilter: configs.pngFilter,
        pngLevel: configs.pngLevel,
      ),
    );
    encodeStopwatch.stop();
    
    stopwatch.stop();
    final outputSize = result != null ? '${(result.length / 1024).toStringAsFixed(0)}KB' : 'null';
    debugPrint(
      '[BENCHMARK] _convertOnMainThread.encode: ${encodeStopwatch.elapsedMilliseconds}ms',
    );
    debugPrint(
      '[BENCHMARK] _convertOnMainThread TOTAL: ${stopwatch.elapsedMilliseconds}ms (size: $imageSize, format: ${configs.outputFormat.name}, output: $outputSize)',
    );
    
    return result;
  }

  /// Prepares the image data required for conversion in a separate thread.
  /// This includes configuring the desired output format, quality, and other
  /// parameters as specified in the `configs`. The generated data is then
  /// sent to the thread manager for processing.
  ///
  /// - [image]: The `ui.Image` to convert.
  /// - [id]: A unique identifier for the conversion task.
  /// - [format]: The desired output format for the image.
  ///
  /// Returns an `ImageConvertThreadRequest` containing the image data and
  /// configuration settings for thread-based processing.
  Future<ImageConvertThreadRequest> _generateSendImageData({
    required ui.Image image,
    required String id,
    required OutputFormat format,
  }) async {
    return ImageConvertThreadRequest(
      id: id,
      generateOnlyImageBounds: configs.cropToDrawingBounds,
      outputFormat: format,
      jpegChroma: configs.jpegChroma,
      jpegQuality: configs.jpegQuality,
      jpegBackgroundColor: configs.jpegBackgroundColor.toARGB32(),
      pngFilter: configs.pngFilter,
      pngLevel: configs.pngLevel,
      singleFrame: configs.singleFrame,
      image: await convertFlutterUiToImage(image),
    );
  }
}
