import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '/helpers/TensorFlowHelper.dart';

class ImageProcessor {
  final String originalImagePath;
  final String selectedHairImagePath;

  ImageProcessor(this.originalImagePath, this.selectedHairImagePath);

  static const int maskDimension = 256;

  Future<Uint8List> processImages() async {
    final tensorFlowHelper = TensorFlowHelper();

    // Carregar o modelo
    await tensorFlowHelper.loadModel(modelPath: 'assets/models/model.tflite');

    // Carregar bytes das imagens
    final originalImageBytes = await _loadImageBytes(originalImagePath);
    final hairImageBytes = await _loadImageBytes(selectedHairImagePath);

    // Verificar validade das imagens carregadas
    if (originalImageBytes.isEmpty) {
      throw Exception("Erro: Bytes da imagem original estão vazios.");
    }

    final originalImage = img.decodeImage(originalImageBytes);
    if (originalImage == null) {
      throw Exception("Erro ao decodificar a imagem original.");
    }

    // Obter máscara de cabelo
    final hairMask = await tensorFlowHelper.getHairMask(originalImageBytes);
    if (hairMask == null || hairMask.length != maskDimension * maskDimension) {
      throw Exception("Erro ao obter ou validar a máscara de cabelo.");
    }

    // Redimensionar máscara
    final resizedMask = _resizeMaskToImageSize(
        hairMask, maskDimension, originalImage.width, originalImage.height);
    final blurredMask = _blurMask(resizedMask, 100);


    // Aplicar máscara de cabelo
    final processedImage = _applyHairMask(
      originalImage,
      hairImageBytes,
      hairMask: hairMask,
      maskMargin: 0, // Ajustável
    );

   

    // Fechar o modelo
    await tensorFlowHelper.closeModel();

    return processedImage;
  }

  img.Image _blurMask(img.Image maskImage, int intensity) {
    return img.smooth(maskImage, weight: intensity);
  }

  img.Image _resizeMaskToImageSize(
      List<int> mask, int maskDimension, int targetWidth, int targetHeight) {
    final maskImage = img.Image(width: maskDimension, height: maskDimension);
    for (int y = 0; y < maskDimension; y++) {
      for (int x = 0; x < maskDimension; x++) {
        final index = y * maskDimension + x;
        final value = mask[index] == 1 ? 255 : 0;
        maskImage.setPixelRgb(x, y, value, value, value);
      }
    }

    // Redimensiona a máscara para o tamanho da imagem original
    return img.copyResize(maskImage, width: targetWidth, height: targetHeight);
  }

  Future<Uint8List> _loadImageBytes(String path) async {
    if (path.startsWith('assets/')) {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } else {
      final file = File(path);
      return await file.readAsBytes();
    }
  }

 

  Uint8List _applyHairMask(
  img.Image originalImage,
  Uint8List hairImageBytes, {
  required List<int> hairMask,
  int maskMargin = 0,
  double scale = 0.8,
}) {
  final hairImage = img.decodeImage(hairImageBytes);
  if (hairImage == null) {
    throw Exception("Erro ao decodificar a imagem de cabelo.");
  }

  final newWidth = (originalImage.width * scale).toInt();
  final newHeight = (originalImage.height * scale).toInt();
  final resizedHairImage = img.copyResize(
    hairImage,
    width: newWidth,
    height: newHeight,
    interpolation: img.Interpolation.linear,
  );

  final offsetX = (originalImage.width - newWidth) ~/ 2;
  final offsetY = (originalImage.height - newHeight) ~/ 2;

  for (int y = 0; y < newHeight; y++) {
    for (int x = 0; x < newWidth; x++) {
      final targetX = x + offsetX;
      final targetY = y + offsetY;

      if (targetX < 0 || targetX >= originalImage.width || targetY < 0 || targetY >= originalImage.height) {
        continue;
      }

      final maskX = (targetX * 256) ~/ originalImage.width;
      final maskY = (targetY * 256) ~/ originalImage.height;

      if (_isWithinMask(hairMask, maskX, maskY, 256, maskMargin)) {
        final hairPixel = resizedHairImage.getPixel(x, y);

        // Acessando os componentes de cor diretamente
        final hairAlpha = hairPixel.a;
        final hairRed = hairPixel.r;
        final hairGreen = hairPixel.g;
        final hairBlue = hairPixel.b;

        if (hairAlpha > 0) {
          final bgPixel = originalImage.getPixel(targetX, targetY);

          final bgRed = bgPixel.r;
          final bgGreen = bgPixel.g;
          final bgBlue = bgPixel.b;

          // Aplicando a transparência correta
          final alphaFactor = hairAlpha / 255.0;
          final blendedRed = ((hairRed * alphaFactor) + (bgRed * (1 - alphaFactor))).toInt();
          final blendedGreen = ((hairGreen * alphaFactor) + (bgGreen * (1 - alphaFactor))).toInt();
          final blendedBlue = ((hairBlue * alphaFactor) + (bgBlue * (1 - alphaFactor))).toInt();

          // Criando o pixel misturado
          final blendedPixel = img.ColorRgba8(blendedRed, blendedGreen, blendedBlue, 255);

          originalImage.setPixel(targetX, targetY, blendedPixel);
        }
      }
    }
  }

  return Uint8List.fromList(img.encodePng(originalImage));
}

  bool _isWithinMask(
    List<int> hairMask,
    int maskX,
    int maskY,
    int maskDimension,
    int maskMargin,
  ) {
    for (int i = -maskMargin; i <= maskMargin; i++) {
      for (int j = -maskMargin; j <= maskMargin; j++) {
        final marginX = maskX + i;
        final marginY = maskY + j;

        if (marginX >= 0 &&
            marginX < maskDimension &&
            marginY >= 0 &&
            marginY < maskDimension &&
            hairMask[marginY * maskDimension + marginX] == 1) {
          return true;
        }
      }
    }
    return false;
  }
}
