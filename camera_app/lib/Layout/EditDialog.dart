import 'dart:ffi';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera_app/Layout/PhotoFilters.dart';
import 'package:flutter/material.dart';
import 'EditCarouselOptions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img; // Para manipulação de imagens
import 'ColorPicker.dart';
import 'package:flutter/foundation.dart';
import '../Filters/filter_type.dart';

class EditDialog extends StatefulWidget {
  final File image; // Imagem original
  final ui.Image? processedImage; // Imagem processada (pode ser null)

  EditDialog({
    required this.image,
    this.processedImage,
  });

  @override
  _EditDialogState createState() => _EditDialogState();
}

Uint8List? _processImageInBackground(List<Object> params) {
  Uint8List imageBytes = params[0] as Uint8List;
  int filterIndex = params[1] as int;
  double value = params[2] as double;

  img.Image? image = img.decodeImage(imageBytes);

  if (image == null) {
    print("Erro: Falha ao decodificar imagem no background!");
    return null;
  }

  FilterType filter = FilterType.values[filterIndex];

  img.Image adjustedImage;
  switch (filter) {
    case FilterType.brightness:
      adjustedImage = img.adjustColor(image, brightness: value);
      break;
    case FilterType.contrast:
      adjustedImage = img.adjustColor(image, contrast: value);
      break;
    case FilterType.saturation:
      adjustedImage = img.adjustColor(image, saturation: value);
      break;
    case FilterType.exposure:
      adjustedImage = img.adjustColor(image, exposure: value);
      break;
    case FilterType.hue:
      adjustedImage = img.adjustColor(image, hue: value);
      break;
  }

  return Uint8List.fromList(img.encodeJpg(adjustedImage));
}

class _EditDialogState extends State<EditDialog> {
  ui.Image? processedImage;
  Uint8List? processedImageBytes;
  Offset _hairPosition = Offset(100, 100);
  bool isLoading = false;
  String _selectedOption = 'Select Hair';
  Color _selectedColor = Colors.black;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    processedImage = widget.processedImage;
    if (processedImage != null) {
      _convertImageToBytes(processedImage!);
    }
  }

  void _onColorSelected(Color color) {
    setState(() {
      _selectedColor = color;
    });

    if (processedImageBytes != null) {
      // Altera cor do cabelo da imagem
      Uint8List newImageBytes = _changeHairColor(
          processedImageBytes!, // Imagem original
          _selectedColor // Cor selecionada
          );

      setState(() {
        processedImageBytes = newImageBytes;
      });
    }
  }

  void _applyFilter(FilterType filter, double value) async {
    if (widget.image == null) {
      return;
    }

    bool exists = await widget.image.exists();
    if (!exists) {
      return;
    }

    Uint8List imageBytes = await widget.image.readAsBytes();

    if (imageBytes.isEmpty) {
      return;
    }

   
    setState(() => _isProcessing = true);

    Uint8List? updateBytes = await compute(
      _processImageInBackground,
      [imageBytes, filter.index, value],
    );

    if (updateBytes != null && mounted) {
      setState(() {
        processedImageBytes = updateBytes;
        _isProcessing = false;
      });
    } else {
      print("Erro: Falha ao processar imagem!");
    }
  }

  Future<void> _convertImageToBytes(ui.Image image) async {
    try {
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        setState(() {
          processedImageBytes = byteData.buffer.asUint8List();
        });
      }
    } catch (e) {
      print('Erro ao converter imagem: $e');
    }
  }

  Future<void> _saveImageToCache(Uint8List imageBytes) async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final imagePath = '${directory.path}/image_${timestamp}.png';
      final file = File(imagePath);
      await file.writeAsBytes(imageBytes);
      print('Imagem salva em: $imagePath');
    } catch (e) {
      print('Erro ao salvar a imagem: $e');
    }
  }

  Uint8List _resizeImage(Uint8List imageBytes, int width, int height) {
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Erro ao decodificar a imagem');
    }
    img.Image resizedImage =
        img.copyResize(image, width: width, height: height);
    return Uint8List.fromList(img.encodePng(resizedImage));
  }

  static Uint8List _changeHairColor(Uint8List imageBytes, Color newColor) {
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Erro ao decodificar a imagem');
    }

    int imageHeight = image.height;
    int imageWidth = image.width;

    // Ajuste do centro e das dimensões da elipse
    double centerX = imageWidth / 2; // Centro da imagem (horizontal)
    double centerY =
        imageHeight * 0.75; // Ajustando o centro da elipse mais para baixo
    double a =
        imageWidth * 0.98; // Largura da elipse (20% da largura da imagem)
    double b = imageHeight * 0.34; // Altura da elipse (40% da altura da imagem)

    for (int y = 0; y < imageHeight; y++) {
      for (int x = 0; x < imageWidth; x++) {
        img.Pixel pixel = image.getPixel(x, y);

        // Verificar se o pixel está fora da área da elipse
        if (!_isInFaceEllipse(x, y, centerX, centerY, a, b)) {
          // Se o pixel estiver fora da elipse, aplicar a coloração do cabelo
          if (_isHairPixel(x, y, imageWidth, imageHeight, image)) {
            double originalR = pixel.r / 255.0;
            double originalG = pixel.g / 255.0;
            double originalB = pixel.b / 255.0;

            double luminance =
                0.299 * originalR + 0.587 * originalG + 0.114 * originalB;

            double brightnessFactor = luminance < 0.2 ? 1.15 : 1.0;
            originalR = (originalR * brightnessFactor).clamp(0, 1);
            originalG = (originalG * brightnessFactor).clamp(0, 1);
            originalB = (originalB * brightnessFactor).clamp(0, 1);

            double blendFactor = 0.4;
            int r = ((newColor.red * blendFactor) +
                    (originalR * 255 * (1 - blendFactor)))
                .toInt();
            int g = ((newColor.green * blendFactor) +
                    (originalG * 255 * (1 - blendFactor)))
                .toInt();
            int b = ((newColor.blue * blendFactor) +
                    (originalB * 255 * (1 - blendFactor)))
                .toInt();

            if (luminance < 0.2) {
              r = (r * 1.05).clamp(0, 255).toInt();
              g = (g * 1.05).clamp(0, 255).toInt();
              b = (b * 1.05).clamp(0, 255).toInt();
            }

            image.setPixel(x, y, img.ColorRgb8(r, g, b));
          }
        }
      }
    }

    return Uint8List.fromList(img.encodePng(image));
  }

  static bool _isInFaceEllipse(
      int x, int y, double centerX, double centerY, double a, double b) {
    // Verifica se o pixel está dentro da elipse
    double dx = x - centerX;
    double dy = y - centerY;

    return (dx * dx) / (a * a) + (dy * dy) / (b * b) <= 1;
  }

  static bool _isHairPixel(
      int x, int y, int imageWidth, int imageHeight, img.Image image) {
    img.Pixel pixel = image.getPixel(x, y);
    int r = pixel.r.toInt();
    int g = pixel.g.toInt();
    int b = pixel.b.toInt();

    // Calculando luminosidade
    double luminosity = 0.2126 * r + 0.7152 * g + 0.0722 * b;

    // Condição de detecção para cabelos escuros ou dentro da faixa de cor do cabelo
    bool isDarkHair = luminosity < 90;
    bool isColorInHairRange = (r < 85 && g < 75 && b < 65);

    // Verifica se o pixel está dentro da faixa de cabelo (fora da elipse)
    return (isDarkHair || isColorInHairRange);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(0),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.grey.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 45,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 8,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      padding:
                          EdgeInsets.zero, // Remove o padding interno padrão
                      constraints:
                          BoxConstraints(), // Remove restrições desnecessárias
                      onPressed: () {
                        print('Close image clicked');
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 8,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: Icon(Icons.undo,
                            color: Colors.white), // Ícone de desfazer
                        onPressed: () {
                          setState(() {
                            // Restaure a imagem original ou limpe as alterações, por exemplo:
                            processedImageBytes =
                                null; // Aqui você pode resetar as alterações
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.done, color: Colors.white),
                        onPressed: () async {
                          if (processedImageBytes != null) {
                            await _saveImageToCache(processedImageBytes!);
                            Navigator.pop(context, true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Nenhuma imagem processada disponível.'),
                              ),
                            );
                          }
                        },
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: 280,
                    maxWidth: 400,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      processedImageBytes != null
                          ? Image.memory(
                              processedImageBytes!,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              widget.image,
                              fit: BoxFit.cover,
                            ),
                      if (isLoading)
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SegmentedButton<String>(
                    segments: const <ButtonSegment<String>>[
                      ButtonSegment<String>(
                          value: 'hairs',
                          label: Text('Hairs'),
                          icon: Icon(Icons.cut)),
                      ButtonSegment<String>(
                        value: 'colors',
                        label: Text('Colors'),
                        icon: Icon(Icons.color_lens),
                      ),
                      ButtonSegment<String>(
                          value: 'filters',
                          label: Text('Filters'),
                          icon: Icon(Icons.tune)),
                    ],
                    selected: <String>{_selectedOption},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedOption = newSelection.first;
                      });
                      print('Selected: $_selectedOption');
                    },
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      selectedBackgroundColor: Colors.white,
                      selectedForegroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
                child: _selectedOption == 'hairs'
                    ? Center(
                        child: EditCarouselOptions(
                        imagePaths: const [
                          'assets/haircut/image1.png',
                          'assets/haircut/image2.png',
                          'assets/haircut/image3.png',
                          'assets/haircut/image4.png',
                          'assets/haircut/image5.png',
                          'assets/haircut/image6.png',
                          'assets/haircut/image7.png',
                          'assets/haircut/image8.jpg',
                          'assets/haircut/image9.png',
                          'assets/haircut/image10.png',
                          'assets/haircut/image11.png',
                          'assets/haircut/image12.png',
                          'assets/haircut/image13.png',
                          'assets/haircut/image14.png',
                          'assets/haircut/image15.png',
                          'assets/haircut/image16.png',
                          'assets/haircut/image17.png'
                          
                        ],
                        originalImagePath: widget.image.path,
                        onImageProcessed: (ui.Image? newImage) async {
                          setState(() {
                            isLoading = true;
                          });
                          if (newImage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Nenhum Rosto detectado...'),
                              ),
                            );
                            setState(() {
                              isLoading = false;
                            });
                            return;
                          }
                          await _convertImageToBytes(newImage);

                          if (processedImageBytes != null) {
                            try {
                              Uint8List resizedImageBytes = _resizeImage(
                                processedImageBytes!,
                                600,
                                800,
                              );
                              setState(() {
                                processedImageBytes = resizedImageBytes;
                                processedImage = newImage;
                                isLoading = false;
                              });
                            } catch (e) {
                              print('Erro ao redimensionar a imagem: $e');
                              setState(() {
                                isLoading = false;
                              });
                            }
                          }
                        },
                      ))
                    : _selectedOption == 'colors'
                        ? SingleChildScrollView(
                            child: Center(
                              child: ColorPickerScreen(
                                  onColorSelected: _onColorSelected),
                            ),
                          )
                        : Center(
                            child: FilteredImageWidget(
                              originalImage: widget.image,
                              processedImage: processedImageBytes,
                              onFilterChanged:
                                  (String label, double value) async {
                                FilterType? filterType;
                                switch (label) {
                                  case "Brightness":
                                    filterType = FilterType.brightness;
                                    break;
                                  case "Contrast":
                                    filterType = FilterType.contrast;
                                    break;
                                  case "Saturation":
                                    filterType = FilterType.saturation;
                                    break;
                                  case "Hue":
                                    filterType = FilterType.hue;
                                    break;
                                  case "Exposure":
                                    filterType = FilterType.exposure;
                                    break;
                                  default:
                                    print("Filtro inválido: $label");
                                    return;
                                }

                                _applyFilter(filterType, value);
                              },
                            ),
                          )),
          ],
        ),
      ),
    );
  }
}
