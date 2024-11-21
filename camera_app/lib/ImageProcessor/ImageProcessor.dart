import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '/helpers/TensorFlowHelper.dart';

class ImageProcessor {
  final String originalImagePath;
  final String selectedHairImagePath;

  ImageProcessor(this.originalImagePath, this.selectedHairImagePath);

  Future<Uint8List> processImages() async {
    TensorFlowHelper tensorFlowHelper = TensorFlowHelper();

    // Carregar o modelo
    await tensorFlowHelper.loadModel(modelPath: 'assets/models/model.tflite');

    // Carregar os bytes da imagem original e da imagem de cabelo
    Uint8List originalImageBytes = await _loadImageBytes(originalImagePath);
    Uint8List hairImageBytes = await _loadImageBytes(selectedHairImagePath);

    // Verificar se os bytes da imagem original estão vazios
    if (originalImageBytes.isEmpty) {
      throw Exception("Erro: Bytes da imagem original estão vazios.");
    }

    // Decodificar a imagem original
    img.Image? originalImage = img.decodeImage(originalImageBytes);

    if (originalImage == null) {
      throw Exception("Erro ao decodificar a imagem original.");
    }

    // Obter a máscara de cabelo
    List<int>? hairMask =
        await tensorFlowHelper.getHairMask(originalImageBytes);

    // Verificar o tamanho da máscara de cabelo
    if (hairMask == null || hairMask.length != 256 * 256) {
      print("Erro: Máscara de cabelo está com tamanho incompatível.");
      print("Tamanho da máscara de cabelo: ${hairMask?.length}");
      print("Tamanho esperado: ${256 * 256}");
      throw Exception(
          "Erro ao obter a máscara de cabelo ou tamanho incompatível.");
    }

    // Redimensionar a máscara de cabelo para corresponder ao tamanho da imagem original
    img.Image maskImage =
        _resizeMaskToImageSize(hairMask, 256, 256); // Tamanho 128x128

    // Converter `maskImage` para `List<int>`
    List<int> maskImageData = maskImage.getBytes();

    // Aplicar a máscara de cabelo
    Uint8List processedImage = _applyHairMask(originalImage, hairImageBytes,
        hairMask: hairMask, // Parâmetro nomeado para a máscara de cabelo
        maskImageData:
            maskImageData // Parâmetro nomeado para os dados da máscara
        );

    // Fechar o modelo
    await tensorFlowHelper.closeModel();

    return processedImage;
  }

  img.Image _resizeMaskToImageSize(List<int> mask, int width, int height) {
    img.Image maskImage = img.Image(width: width, height: height);

    // Preencher a imagem com os valores da máscara
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int index = y * width + x;
        int value = mask[index] == 1 ? 255 : 0;

        maskImage.setPixelRgb(x, y, value, value, value);
      }
    }
    final blurredImage = img.gaussianBlur(maskImage, radius: 10);
    return blurredImage;
  }

  Future<Uint8List> _loadImageBytes(String path) async {
    if (path.startsWith('assets/')) {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } else {
      final File file = File(path);
      return await file.readAsBytes();
    }
  }

  Uint8List _applyHairMask(
    img.Image originalImage,
    Uint8List hairImageBytes, {
    required List<int> hairMask,
    required List<int> maskImageData,
    double scale = 0.70,
    double widthIncrease = 0.90,
    double heightIncrease = 1,
    int maskMargin = 0, // Adicione uma margem para a máscara
  
  }) {
    // Decodifique a imagem de cabelo
    final hairImage = img.decodeImage(hairImageBytes);
    if (hairImage == null) {
      throw Exception("Erro ao decodificar a imagem de cabelo.");
    }

    // Redimensione a imagem de cabelo
    final newWidth = (originalImage.width * scale * widthIncrease).toInt();
    final newHeight = ((originalImage.height * scale) - heightIncrease).toInt();
    final resizedHairImage = img.copyResize(hairImage,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear);

    // Calcule o deslocamento para centralizar a imagem de cabelo
    final offsetX = (originalImage.width - newWidth) ~/ 2;
    final offsetY = (originalImage.height - newHeight) ~/ 2;

    // Adapte as dimensões da máscara
    final maskWidth = (256 * originalImage.width) ~/ originalImage.width;
    final maskHeight = (256 * originalImage.height) ~/ originalImage.height;

    
    // Aplique a máscara de cabelo
    for (int y = 0; y < newHeight; y++) {
      for (int x = 0; x < newWidth; x++) {
        final targetX = x + offsetX;
        final targetY = y + offsetY;

        if (targetX >= 0 &&
            targetX < originalImage.width &&
            targetY >= 0 &&
            targetY < originalImage.height) {
          // Verifique a posição (targetX, targetY) dentro da máscara com margem
          final maskX = (targetX * maskWidth) ~/ originalImage.width;
          final maskY = (targetY * maskHeight) ~/ originalImage.height;

          // Aplique a margem ao redor da máscara
          bool isWithinMargin = false;
          for (int i = -maskMargin; i <= maskMargin; i++) {
            for (int j = -maskMargin; j <= maskMargin; j++) {
              final marginX = maskX + i;
              final marginY = maskY + j;
              if (marginX >= 0 &&
                  marginX < maskWidth &&
                  marginY >= 0 &&
                  marginY < maskHeight &&
                  hairMask[marginY * maskWidth + marginX] == 1) {
                isWithinMargin = true;
                break;
              }
            }
            if (isWithinMargin) break;
          }

          // Aplique a imagem de cabelo se estiver dentro da margem
            if (isWithinMargin) {
          final hairPixel = resizedHairImage.getPixel(x, y);

          // Use transparência apenas se necessário
          if (hairPixel.a > 0) { // Componente alfa é maior que 0
            originalImage.setPixel(targetX, targetY, hairPixel);
          }
        }
        }
      }
    }

    // Codifique a imagem final como PNG e retorne como Uint8List
    return Uint8List.fromList(img.encodePng(originalImage));
  }
}
