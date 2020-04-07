import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';

class OcrUtils {
  static Future<void> extractText({
    @required Uint8List bodyBytes,
  }) async {
    String extractText;
    try {
      final Directory directory = await getTemporaryDirectory();
      final String imagePath = join(
        directory.path,
        "tmp.jpg",
      );
      var start = DateTime.now();
//      var grayscaleImage = image.grayscale(image.Image.fromBytes(
//          78, 22, bodyBytes,
//          channels: image.Channels.rgb));
//      bodyBytes = grayscaleImage.getBytes(format: image.Format.rgb).getBytes(format: image.Format.rgb);
      await File(imagePath).writeAsBytes(bodyBytes);
      extractText = await TesseractOcr.extractText(
        imagePath,
        language: "eng",
      );
      final replaceText = extractText.replaceAll(RegExp("[^A-Z^0-9]"), '');
      var end = DateTime.now();
      final processTime =
          end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
      print('process time = $processTime ms');
      return replaceText;
    } on PlatformException {
//      extractText = 'Failed to extract text';
    }
    return '';
  }
}
