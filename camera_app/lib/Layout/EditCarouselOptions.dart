import 'package:camera_app/ImageProcessor/ImageProcessor.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class EditCarouselOptions extends StatefulWidget {
  final List<String> imagePaths;
  final String originalImagePath;
  final Function(ui.Image?) onImageProcessed;

  const EditCarouselOptions({
    Key? key,
    required this.imagePaths,
    required this.originalImagePath,
    required this.onImageProcessed,
  }) : super(key: key);

  @override
  _EditCarouselOptionsState createState() => _EditCarouselOptionsState();
}

class _EditCarouselOptionsState extends State<EditCarouselOptions> {
  int _selectedIndex = -1;
  ui.Image? _processedImage;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CarouselSlider(
              options: CarouselOptions(
                height: 70,
                enlargeCenterPage: true,
                enableInfiniteScroll: true,
                autoPlay: false,
              ),
              items: widget.imagePaths.asMap().entries.map((entry) {
                int index = entry.key;
                String imagePath = entry.value;

                return Builder(
                  builder: (BuildContext context) {
                    return GestureDetector(
                      onTap: () async {
                        setState(() {
                          _selectedIndex = index;
                          _isLoading = true;
                        });

                        try {
                          String selectedHairImagePath = imagePath;
                          ImageProcessor processor = ImageProcessor(
                            widget.originalImagePath,
                            selectedHairImagePath,
                          );

                          print('Iniciando o processamento da imagem...');
                          Uint8List processedImageBytes =
                              await processor.processImages();
                          print(
                              'Imagem processada com sucesso. Convertendo para ui.Image...');
                          ui.Image processedImage =
                              await _uint8ListToUiImage(processedImageBytes);

                          setState(() {
                            _processedImage = processedImage;
                            widget.onImageProcessed(processedImage);
                          });
                        } catch (error) {
                          print('Erro ao processar a imagem: $error');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Erro ao processar imagem')),
                          );
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                      child: ClipOval(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                image: DecorationImage(
                                  image: AssetImage(imagePath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              width: 70,
                             
                            ),
                            if (_isLoading && _selectedIndex == index)
                              const CircularProgressIndicator(),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Future<ui.Image> _uint8ListToUiImage(Uint8List uint8List) async {
    try {
      final codec = await ui.instantiateImageCodec(uint8List);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      print('Erro ao converter Uint8List para ui.Image: $e');
      throw e;
    }
  }
}
