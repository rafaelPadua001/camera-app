import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class TensorFlowHelper {
  Interpreter? _interpreter;

  Future<void> loadModel({required String modelPath}) async {
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      print('Modelo carregado com sucesso.');

      // Verifica as dimensões de entrada e saída
      var inputShape = _interpreter?.getInputTensor(0).shape;
      var outputShape = _interpreter?.getOutputTensor(0).shape;
      print('Dimensões esperadas de entrada: $inputShape');
      print('Dimensões esperadas de saída: $outputShape');
    } catch (e) {
      print('Erro ao carregar o modelo: $e');
    }
  }

  Future<List<int>?> getHairMask(Uint8List imageBytes) async {
  if (_interpreter == null) {
    print('Erro: O interpretador não está inicializado.');
    return null;
  }

  try {
    // Preprocessa a imagem com normalização para o formato de entrada do modelo
    Float32List input = _preprocessImage(imageBytes, 256, 256);
    if (input.isEmpty) {
      print('Erro: O input da imagem é vazio ou inválido.');
      return null;
    }

    // Prepara o tensor de entrada e saída
    var inputTensor = input.reshape([1, 256, 256, 3]);

    // Cria uma saída com a forma esperada
    var output = List.generate(1, (_) => List.generate(256, (_) => List.generate(256, (_) => [0.0])));

    // Executa o modelo
    _interpreter?.run(inputTensor, output);

    // Verificar a forma da saída
    print('Saída do modelo: $output');

    // Converte a saída para uma máscara binária
    var binaryMask = output[0]
        .expand((row) => row
            .expand((pixel) => pixel.map<int>((value) => value > 0.5 ? 1 : 0)))
        .toList();

    // Verificar o tamanho da máscara
    if (binaryMask.length != 65536) {
      print('Erro: A máscara de cabelo tem tamanho incorreto.');
      return null;
    }

    return binaryMask;
  } catch (e) {
    print('Erro ao executar a segmentação: $e');
    return null;
  }
}
  Float32List _preprocessImage(Uint8List imageBytes, int width, int height) {
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      print('Erro: Não foi possível decodificar a imagem.');
      return Float32List(0); // Retorna uma lista vazia
    }

    // Redimensiona a imagem para 128x128
    img.Image resizedImage = img.copyResize(image, width: width, height: height);

    // Criação de uma lista de tamanho adequado para armazenar os valores da imagem
    Float32List input = Float32List(width * height * 3);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        img.Pixel pixel = resizedImage.getPixel(x, y);

        // Acessa os componentes RGB diretamente
        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();

        // Normaliza para o intervalo [0, 1]
        input[(y * width + x) * 3 + 0] = r / 255.0;
        input[(y * width + x) * 3 + 1] = g / 255.0;
        input[(y * width + x) * 3 + 2] = b / 255.0;
      }
    }

    return input;
  }

 List<int> _convertToBinaryMask(List<List<List<double>>> output) {
  // Converte a saída do modelo para uma máscara binária
  return output.expand((sublist) => sublist.expand((value) => value.map<int>((pixel) => pixel > 0.5 ? 1 : 0))).toList();
}

  Future<void> closeModel() async {
    _interpreter?.close();
    print('Modelo fechado.');
  }
}
