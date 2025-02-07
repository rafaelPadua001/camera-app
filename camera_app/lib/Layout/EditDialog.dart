import 'dart:ffi';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'EditCarouselOptions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img; // Para manipulação de imagens
import 'ColorPicker.dart';

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

class _EditDialogState extends State<EditDialog> {
  ui.Image? processedImage;
  Uint8List? processedImageBytes;
  Offset _hairPosition = Offset(100, 100);
  bool isLoading = false;
  String _selectedOption = 'Select Hair';
  Color _selectedColor = Colors.black;

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

  if (processedImageBytes != null ) {
    // Altera cor do cabelo da imagem
    Uint8List newImageBytes = _changeHairColor(
      processedImageBytes!,  // Imagem original
      _selectedColor         // Cor selecionada
    );

    setState(() {
      processedImageBytes = newImageBytes;
    });
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

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      img.Pixel pixel = image.getPixel(x, y);

      if (_isHairPixel(pixel)) {
        // Altera a cor do cabelo para a cor selecionada
        int r = ((pixel.r * (1 - 0.6)) + (newColor.red * 0.6)).toInt();
        int g = ((pixel.g * (1 - 0.6)) + (newColor.green * 0.6)).toInt();
        int b = ((pixel.b * (1 - 0.6)) + (newColor.blue * 0.6)).toInt();

        // Certifica-se de que os valores de r, g e b estejam dentro do intervalo [0, 255]
        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        // Define o novo pixel
        image.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }
  }

  return Uint8List.fromList(img.encodePng(image));
}

static bool _isHairPixel(img.Pixel pixel) {
  // Garantir que r, g e b sejam int
  int r = pixel.r.toInt();
  int g = pixel.g.toInt();
  int b = pixel.b.toInt();

  // Calculando a luminosidade do pixel
  double luminosity = 0.2126 * r + 0.7152 * g + 0.0722 * b;

  // Definir uma faixa para identificar cabelo escuro, ajustando para os valores de luminosidade e cores
  bool isDarkHair = luminosity < 80;  // Valor ajustável, indicando pixel escuro
  bool isColorInHairRange = (r < 70 && g < 60 && b < 50); // Faixa de cores específicas

  // O pixel será considerado cabelo se atender a uma das duas condições
  return isDarkHair || isColorInHairRange;
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
            SizedBox(height: 10),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: 380,
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
            SizedBox(height: 2),
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
                      ButtonSegment<String>(value: 'cut', label: Text('Cut')),
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
                          } else {
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
                          }
                        },
                      ))
                    : _selectedOption == 'colors'
                        ? SingleChildScrollView(
                            child: Center(
                              child: ColorPickerScreen(
                                  onColorSlected: _onColorSelected),
                            ),
                          )
                        : Center(
                            child: Text('Cut option selected'),
                          )),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
                SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    if (processedImageBytes != null) {
                      await _saveImageToCache(processedImageBytes!);
                      Navigator.pop(context, true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Nenhuma imagem processada disponível.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
