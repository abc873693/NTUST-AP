import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as img;

enum SystemType {
  stu,
  course,
}

class CaptchaUtilConfig {
  final int digitsCount;
  final int imageHeight;
  final int imageWidth;
  final String modelName;
  final int cropX;
  final int cropY;
  final int cropWidth;
  final int cropHeight;
  final bool needResize;

  CaptchaUtilConfig({
    this.digitsCount,
    this.imageWidth,
    this.imageHeight,
    this.modelName,
    this.cropX,
    this.cropY,
    this.cropWidth,
    this.cropHeight,
    this.needResize,
  });

  factory CaptchaUtilConfig.load({
    @required SystemType type,
  }) {
    switch (type) {
      case SystemType.stu:
        return CaptchaUtilConfig(
          digitsCount: 6,
          imageWidth: 57,
          imageHeight: 13,
          modelName: "assets/model-ap.tflite",
          cropX: 10,
          cropY: 10,
          cropWidth: 114,
          cropHeight: 26,
          needResize: true,
        );
      case SystemType.course:
      default:
        return CaptchaUtilConfig(
          digitsCount: 6,
          imageWidth: 61,
          imageHeight: 14,
          modelName: "assets/model.tflite",
          cropX: 5,
          cropY: 3,
          cropWidth: 61,
          cropHeight: 14,
          needResize: false,
        );
        break;
    }
  }
}

class CaptchaUtils {
  static Future<String> extractByTfLite({
    @required SystemType type,
    @required Uint8List bodyBytes,
  }) async {
    final config = CaptchaUtilConfig.load(type: type);
    final digitsCount = config.digitsCount;
    final imageHeight = config.imageHeight;
    final imageWidth = config.imageWidth;
    try {
      final Directory directory = await getTemporaryDirectory();
      final String imagePath = join(
        directory.path,
        "tmp.jpg",
      );
      await File(imagePath).writeAsBytes(bodyBytes);
      var start = DateTime.now();
      var end = DateTime.now();
      var source = img.decodeImage(File(imagePath).readAsBytesSync());
      var grayscaleImage = img.grayscale(source);
      var crop = img.copyCrop(
        grayscaleImage,
        config.cropX,
        config.cropY,
        config.cropWidth,
        config.cropHeight,
      );
      if (config.needResize)
        crop = img.copyResize(crop, width: imageWidth, height: imageHeight);
      end = DateTime.now();
      final cropTime =
          end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
      print('crop time = $cropTime ms');
      start = DateTime.now();
      String res = await Tflite.loadModel(
          model: config.modelName,
          labels: "assets/labels.txt",
          numThreads: 1 // defaults to 1
          );
      end = DateTime.now();
      final loadModelTime =
          end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
      print('loadModel time = $loadModelTime ms');
      var replaceText = '';
      start = DateTime.now();
      final w = (imageWidth ~/ digitsCount), h = imageHeight;
      for (var i = 0; i < digitsCount; i++) {
        var target =
            img.copyCrop(crop, (imageWidth ~/ digitsCount) * i, 0, w, h);
        var recognitions = await Tflite.runModelOnBinary(
            binary: imageToByteListFloat32(target, w, h, 127.5, 255.0),
            // required
            numResults: 1,
            // defaults to 5
            threshold: 0.05,
            // defaults to 0.1
            asynch: true // defaults to true
            );
        replaceText += recognitions.first['label'];
      }
      end = DateTime.now();
      final processTime =
          end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
      print('process time = $processTime ms');
      return replaceText;
    } on PlatformException {}
    return '';
  }

  static Uint8List imageToByteListFloat32(
      img.Image image, int w, int h, double mean, double std) {
    var convertedBytes = Float32List(1 * w * h * 1);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < h; i++) {
      for (var j = 0; j < w; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex] = (img.getRed(pixel)) / std;
        pixelIndex++;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }
}
