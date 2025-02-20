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
    final resizedMask = _resizeMaskToImageSize(hairMask, originalImage.width, originalImage.height);
    final blurredMask = _blurMask(resizedMask, 2);

    // Aplicar máscara de cabelo com melhorias no encaixe
    final processedImage = _applyHairMask(
      originalImage,
      hairImageBytes,
      hairMask: blurredMask,
    );

    // Fechar o modelo
    await tensorFlowHelper.closeModel();

    return processedImage;
  }

  img.Image _blurMask(img.Image maskImage, int intensity) {
    return img.gaussianBlur(maskImage, radius: intensity);
  }

  img.Image _resizeMaskToImageSize(List<int> mask, int targetWidth, int targetHeight) {
    final maskImage = img.Image(
      width: maskDimension,
      height: maskDimension,
      numChannels: 3, // Apenas RGB (sem transparência)
    );

    for (int y = 0; y < maskDimension; y++) {
      for (int x = 0; x < maskDimension; x++) {
        final index = y * maskDimension + x;
        final value = mask[index] == 1 ? 255 : 0; 
        maskImage.setPixelRgb(x, y, value, value, value);
      }
    }

    return img.copyResize(
      maskImage,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );
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

  Uint8List _applyHairMask(img.Image originalImage, Uint8List hairImageBytes,
      {required img.Image hairMask}) {
    final hairImage = img.decodeImage(hairImageBytes);
    if (hairImage == null) {
      throw Exception("Erro ao decodificar a imagem de cabelo.");
    }

    // Ajuste do tamanho do cabelo para encaixe melhorado
    final resizedHair = img.copyResize(
      hairImage,
      width: (originalImage.width * 0.85).toInt(), // 85% da largura original
      height: (originalImage.height * 0.55).toInt(), // 55% da altura original
      interpolation: img.Interpolation.cubic,
    );

    // Ajuste de posição do cabelo na imagem original
    final offsetY = (originalImage.height * 0.10).toInt(); // Move o cabelo para cima

    // Criar uma imagem vazia para alinhar o cabelo corretamente
    final alignedImage = img.Image.from(originalImage);
    img.fill(alignedImage, color: img.ColorRgba8(0, 0, 0, 0)); // Fundo transparente


    // Coloca o cabelo na posição ajustada
    img.compositeImage(alignedImage, resizedHair, dstX: 0, dstY: offsetY);

    // Aplicar a máscara na imagem original pixel por pixel
    for (int y = 0; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        final maskPixel = hairMask.getPixel(x, y).luminance;

        if (maskPixel > 128) { // Se a máscara for "ativa" (branca)
          final hairPixel = alignedImage.getPixel(x, y);
          final originalPixel = originalImage.getPixel(x, y);

          final factor = 0.85; // Mistura suave do cabelo com a imagem original
          final blendedPixel = img.ColorRgba8(
            ((hairPixel.r * factor) + (originalPixel.r * (1 - factor))).toInt(),
            ((hairPixel.g * factor) + (originalPixel.g * (1 - factor))).toInt(),
            ((hairPixel.b * factor) + (originalPixel.b * (1 - factor))).toInt(),
            255,
          );

          originalImage.setPixel(x, y, blendedPixel);
        }
      }
    }

    return Uint8List.fromList(img.encodePng(originalImage));
  }
}
