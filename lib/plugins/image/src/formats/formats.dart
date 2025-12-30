import 'dart:async';

import 'package:ffi_jpeg_encode/ffi_jpeg_encode.dart';
import 'package:flutter/foundation.dart';

import '../image/image.dart';
import 'bmp_encoder.dart';
import 'cur_encoder.dart';
import 'ico_encoder.dart';
import 'jpeg/jpeg_chroma.dart';
import 'jpeg_encoder.dart';
import 'png/png_filter.dart';
import 'png_encoder.dart';
import 'pvr_encoder.dart';
import 'tga_encoder.dart';
import 'tiff_encoder.dart';

/// Encode an [image] to the JPEG format.
Future<Uint8List> encodeJpg(
  Image image, {
  int quality = 100,
  required int backgroundColor,
  JpegChroma chroma = JpegChroma.yuv444,
  Completer<void>? destroy$,
}) async {
  final imageData = image.data;
  if (imageData == null) {
    throw ArgumentError('Cannot encode image: image data is null');
  }

  try {
    final pixels = imageData.buffer.asUint8List();
    final subsampling = switch (chroma) {
      JpegChroma.yuv444 => JpegSubsampling.yuv444,
      JpegChroma.yuv420 => JpegSubsampling.yuv420,
    };

    final bytes = encodeJpegToBytes(
      pixels,
      image.width,
      image.height,
      imageData.numChannels,
      quality: quality,
      subsampling: subsampling,
    );

    return bytes;
  } catch (_) {
    return JpegHealthyEncoder(quality: quality).encode(
      image,
      backgroundColor: backgroundColor,
      chroma: chroma,
      destroy$: destroy$,
    );
  }
}

/// Encode an image to the PNG format.
Uint8List encodePng(Image image,
        {bool singleFrame = false,
        int level = 6,
        PngFilter filter = PngFilter.paeth}) =>
    PngEncoder(filter: filter, level: level)
        .encode(image, singleFrame: singleFrame);

/// Encode an image to the TGA format.
Uint8List encodeTga(Image image) => TgaEncoder().encode(image);

/// Encode an image to the Tiff format.
Uint8List encodeTiff(Image image, {bool singleFrame = false}) =>
    TiffEncoder().encode(image, singleFrame: singleFrame);

/// Encode an [Image] to the BMP format.
Uint8List encodeBmp(Image image) => BmpEncoder().encode(image);

/// Encode an [Image] to the CUR format.
Uint8List encodeCur(Image image, {bool singleFrame = false}) =>
    CurEncoder().encode(image, singleFrame: singleFrame);

/// Encode an image to the ICO format.
Uint8List encodeIco(Image image, {bool singleFrame = false}) =>
    IcoEncoder().encode(image, singleFrame: singleFrame);

/// Encode an image to the PVR format.
Uint8List encodePvr(Image image, {bool singleFrame = false}) =>
    PvrEncoder().encode(image, singleFrame: singleFrame);
