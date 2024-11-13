import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'EditCarouselOptions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img; // Para manipulação de imagens

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

  @override
  void initState() {
    super.initState();
    processedImage = widget.processedImage;
    if (processedImage != null) {
      _convertImageToBytes(processedImage!);
    }
  }

  Future<void> _convertImageToBytes(ui.Image image) async {
    try {
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
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
    img.Image resizedImage = img.copyResize(image, width: width, height: height);
    return Uint8List.fromList(img.encodePng(resizedImage));
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
                    maxHeight: 450,
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 2),
            Expanded(
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
              ),
            ),
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
                          content: Text('Nenhuma imagem processada disponível.'),
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
