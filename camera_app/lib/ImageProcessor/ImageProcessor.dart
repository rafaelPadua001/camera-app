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
    hairMask, originalImage.width, originalImage.height);
    final blurredMask = _blurMask(resizedMask, 6);

    // Aplicar máscara de cabelo
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
    return img.smooth(maskImage, weight: intensity);
  }

  img.Image _resizeMaskToImageSize(
    List<int> mask, int targetWidth, int targetHeight) {
  // Criar imagem sem canal alfa para evitar transparência
  final maskImage = img.Image(
    width: maskDimension,
    height: maskDimension,
    numChannels: 3, // Apenas RGB (sem transparência)
  );

  // Preencher a imagem com os valores binários (preto e branco)
  for (int y = 0; y < maskDimension; y++) {
    for (int x = 0; x < maskDimension; x++) {
      final index = y * maskDimension + x;
      final value = mask[index] == 1 ? 255 : 0; // 1 = branco, 0 = preto
      maskImage.setPixelRgb(x, y, value, value, value); // RGB para branco ou preto
    }
  }

  // Redimensionar a máscara para o tamanho da imagem original
  final resizedMaskImage = img.copyResize(
    maskImage,
    width: targetWidth, // Usa as dimensões da imagem original
    height: targetHeight,
    interpolation: img.Interpolation.nearest, // Para garantir a binarização
  );

  return resizedMaskImage;
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

  // Redimensiona a imagem de cabelo para se ajustar ao tamanho da imagem original
  final resizedHairImage = img.copyResize(
    hairImage,
    width: originalImage.width,
    height: originalImage.height,
  );

  // Aplicar a máscara na imagem original pixel por pixel
  for (int y = 0; y < originalImage.height; y++) {
    for (int x = 0; x < originalImage.width; x++) {
      final maskPixel = hairMask.getPixel(x, y).luminance;

      if (maskPixel > 128) { // Se a máscara for "ativa" (branca)
        // Apenas aplica a cor se a máscara estiver ativa
        final hairPixel = resizedHairImage.getPixel(x, y);
        final originalPixel = originalImage.getPixel(x, y);

        // Aplicação do blendedPixel para mistura mais suave
        final factor = 0.9;
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
