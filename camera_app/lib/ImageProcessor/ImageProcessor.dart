import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math';

class ImageProcessor {
  final String originalImagePath;
  final String selectedHairImagePath;

  ImageProcessor(this.originalImagePath, this.selectedHairImagePath);

  Future<Uint8List> processImages() async {
    // Remover cabelo da imagem original
    final imageWithoutHair = await removeHair();

    // Decodificar a imagem sem cabelo
    img.Image originalImage = img.decodeImage(imageWithoutHair)!;

    // Carregar a imagem de cabelo selecionada
    final selectedHairImageBytes = await _loadImageBytes(selectedHairImagePath);
    img.Image selectedHairImage = img.decodeImage(selectedHairImageBytes)!;

    // Criar as opções para o detector de rosto
    final FaceDetectorOptions options = FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    );

    // Criar o detector de rosto com as opções
    final FaceDetector faceDetector = FaceDetector(options: options);

    // Detectar o rosto na imagem original
    final faces = await faceDetector.processImage(InputImage.fromFilePath(originalImagePath));

    if (faces.isEmpty) {
      throw Exception('Nenhum rosto detectado.');
    }

    Face face = faces.first;

    // Calcular a largura e altura do rosto detectado
    double faceWidth = _calculateFaceWidth(face);
    double faceHeight = face.boundingBox.height.toDouble();

    // Calcular o fator de redimensionamento do cabelo
    double hairWidthFactor = faceWidth / selectedHairImage.width;
    double hairHeightFactor = faceHeight / selectedHairImage.height;

    // Redimensionar a imagem do cabelo
    img.Image resizedHairImage = img.copyResize(
      selectedHairImage,
      width: (selectedHairImage.width * hairWidthFactor * 1.0).toInt(),
      height: (selectedHairImage.height * hairHeightFactor).toInt(),
    );

    // Calcular a posição do cabelo na imagem original
    int hairX = (face.boundingBox.left + (faceWidth / 2) - (resizedHairImage.width / 2)).toInt();
    int hairY = (face.boundingBox.top * 0.54).toInt(); // Ajuste para que o cabelo fique acima do rosto

    // Desenhar o cabelo na imagem original
    img.drawImage(originalImage, resizedHairImage, dstX: hairX, dstY: hairY);

    // Retornar a imagem final
    return Uint8List.fromList(img.encodePng(originalImage));
  }

  Future<Uint8List> _loadImageBytes(String path) async {
    Uint8List bytes;

    // Carregar imagem de assets ou do sistema de arquivos
    if (path.startsWith('assets/')) {
      final data = await rootBundle.load(path);
      bytes = data.buffer.asUint8List();
    } else {
      final File file = File(path);
      bytes = await file.readAsBytes();
    }
    return bytes;
  }

  Future<Face?> _detectFace(Uint8List imageBytes) async {
    final inputImage = InputImage.fromFilePath(originalImagePath);

    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: true,
    );
    final faceDetector = FaceDetector(options: options);

    final List<Face> faces = await faceDetector.processImage(inputImage);
    faceDetector.close();

    if (faces.isNotEmpty) {
      return faces.first;
    }
    return null;
  }

  double _calculateFaceWidth(Face face) {
    final Point<int>? leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final Point<int>? rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final Point<int>? leftEar = face.landmarks[FaceLandmarkType.leftEar]?.position;
    final Point<int>? rightEar = face.landmarks[FaceLandmarkType.rightEar]?.position;

    final Point<int> topOfHead = Point<int>(
      face.boundingBox.topLeft.dx.round(),
      face.boundingBox.topLeft.dy.round(),
    );

    if (leftEye != null && rightEye != null) {
      double eyeDistance = (rightEye.x.toDouble() - leftEye.x.toDouble()).abs();
      double faceHeight = (face.boundingBox.bottomRight.dy - topOfHead.y.toDouble()).abs();
      double refinedWidth = eyeDistance * 1.8;
      double margin = faceHeight * 0.3;

      return refinedWidth + margin;
    } else if (leftEar != null && rightEar != null) {
      double earDistance = (rightEar.x.toDouble() - leftEar.x.toDouble()).abs();
      return earDistance + (earDistance * 0.4);
    } else {
      return face.boundingBox.width.toDouble();
    }
  }

  Future<Uint8List> removeHair() async {
    // Carregar a imagem original
  final originalImageBytes = await _loadImageBytes(originalImagePath);
  img.Image originalImage = img.decodeImage(originalImageBytes)!;

  // Configurar as opções do detector de rosto
  final FaceDetectorOptions options = FaceDetectorOptions(
    enableContours: true, // Habilitar contornos para detecção detalhada
    enableClassification: true, // Habilitar classificação
  );

  // Criar o detector de rosto
  final FaceDetector faceDetector = FaceDetector(options: options);

  // Detectar o rosto na imagem
  final faces = await faceDetector.processImage(InputImage.fromFilePath(originalImagePath));

  if (faces.isEmpty) {
    throw Exception('Nenhum rosto detectado.');
  }

  Face face = faces.first;

  // Estimar a posição e tamanho do cabelo com base na posição do rosto
  double faceWidth = _calculateFaceWidth(face);
  int hairTopY = (face.boundingBox.top - face.boundingBox.height * 0.3).toInt(); // Acima da testa
  int hairBottomY = face.boundingBox.top.toInt(); // Testa

  // Substituir o cabelo com uma região suavizada em vez de um retângulo sólido
  for (int y = hairTopY; y < hairBottomY; y++) {
    for (int x = face.boundingBox.left.toInt(); x < face.boundingBox.right.toInt(); x++) {
      // Aplicar uma técnica de blur para suavizar a área do cabelo
      originalImage = _applyBlurToArea(originalImage, x, y);
    }
  }

  // Retornar a imagem final suavizada
  return Uint8List.fromList(img.encodePng(originalImage));
}

img.Image _applyBlurToArea(img.Image image, int x, int y) {
  // Definir a intensidade do blur
  const int blurRadius = 5;
  
  int r = 0, g = 0, b = 0, count = 0;

  // Aplicar blur gaussiano ao redor da área selecionada
  for (int i = -blurRadius; i <= blurRadius; i++) {
    for (int j = -blurRadius; j <= blurRadius; j++) {
      int newX = x + i;
      int newY = y + j;

      if (newX >= 0 && newX < image.width && newY >= 0 && newY < image.height) {
        int pixelColor = image.getPixel(newX, newY);
        r += img.getRed(pixelColor);
        g += img.getGreen(pixelColor);
        b += img.getBlue(pixelColor);
        count++;
      }
    }
  }

  // Calcular a média das cores ao redor
  r = (r / count).toInt();
  g = (g / count).toInt();
  b = (b / count).toInt();

  // Substituir o pixel na posição atual pela cor média
  image.setPixel(x, y, img.getColor(r, g, b));

  return image;
  }
}
