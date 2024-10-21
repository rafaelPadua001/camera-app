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
    // Carregar as imagens originais
    final originalImageBytes = await _loadImageBytes(originalImagePath);
    final selectedHairImageBytes = await _loadImageBytes(selectedHairImagePath);

    // Decodificar as imagens
    img.Image originalImage = img.decodeImage(originalImageBytes)!;
    img.Image selectedHairImage = img.decodeImage(selectedHairImageBytes)!;

    // Criar as opções para o detector de rosto
    final FaceDetectorOptions options = FaceDetectorOptions(
      enableContours: true, // Por exemplo, habilitar contornos se necessário
      enableClassification: true, // Ativar classificação de rosto se necessário
      // Adicione outras opções conforme necessário
    );

    // Criar o detector de rosto com as opções
    final FaceDetector faceDetector = FaceDetector(options: options);

    // Detectar o rosto na imagem
    final faces = await faceDetector.processImage(InputImage.fromFilePath(originalImagePath));

    if (faces.isEmpty) {
      throw Exception('Nenhum rosto detectado.');
    }

    Face face = faces.first;

    // Calcular a largura e altura do rosto detectado
    double faceWidth = _calculateFaceWidth(face);
    double faceHeight = face.boundingBox.height.toDouble();

    // Calcular o fator de redimensionamento do cabelo com base nas proporções do rosto
    double hairWidthFactor = faceWidth / selectedHairImage.width;
    double hairHeightFactor = faceHeight / selectedHairImage.height; // Ajuste para a altura da testa

    // Redimensionar a imagem do cabelo
    img.Image resizedHairImage = img.copyResize(
      selectedHairImage,
      width: (selectedHairImage.width * hairWidthFactor * 1.1).toInt(), // Aumento de 1%
      height: (selectedHairImage.height * hairHeightFactor).toInt(),
    );

    // Calcular a posição do cabelo na imagem original
    int hairX = (face.boundingBox.left + (faceWidth / 2) - (resizedHairImage.width / 2)).toInt();
    int hairY = (face.boundingBox.top * 0.52).toInt(); // Ajustar para que o cabelo fique acima do rosto

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

    // Configurar o detector de rosto
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate, // Alta precisão
      enableLandmarks: true, // Detectar marcos faciais
    );
    final faceDetector = FaceDetector(options: options);

    // Detectar rostos na imagem
    final List<Face> faces = await faceDetector.processImage(inputImage);

    // Fechar o detector de rosto
    faceDetector.close();

    // Retornar o primeiro rosto detectado, se houver
    if (faces.isNotEmpty) {
      return faces.first;
    }
    return null;
  }

  double _calculateFaceWidth(Face face) {
    // Verifica se os olhos ou orelhas estão presentes
    final Point<int>? leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final Point<int>? rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final Point<int>? leftEar = face.landmarks[FaceLandmarkType.leftEar]?.position;
    final Point<int>? rightEar = face.landmarks[FaceLandmarkType.rightEar]?.position;

    // Converte o canto superior esquerdo da bounding box de Offset para Point<int>
    final Point<int> topOfHead = Point<int>(
      face.boundingBox.topLeft.dx.round(),
      face.boundingBox.topLeft.dy.round(),
    );

    if (leftEye != null && rightEye != null) {
      // Usar a distância entre os olhos como referência para a largura do rosto
      double eyeDistance = (rightEye.x.toDouble() - leftEye.x.toDouble()).abs();

      // Calcular a altura do rosto (da parte superior da cabeça até o queixo)
      double faceHeight = (face.boundingBox.bottomRight.dy - topOfHead.y.toDouble()).abs();

      // Proporção refinada
      double refinedWidth = eyeDistance * 1.7; // Aumentar a proporção
      double margin = faceHeight * 0.2; // Aumentar a margem baseada na altura do rosto

      return refinedWidth + margin; // Largura refinada com margem
    } else if (leftEar != null && rightEar != null) {
      // Usar a distância entre as orelhas para calcular a largura
      double earDistance = (rightEar.x.toDouble() - leftEar.x.toDouble()).abs();
      return earDistance + (earDistance * 0.3); // Aumentar a margem ao usar as orelhas
    } else {
      // Se os marcos faciais não estiverem disponíveis, usar o bounding box
      return face.boundingBox.width.toDouble();
    }
  }
}
