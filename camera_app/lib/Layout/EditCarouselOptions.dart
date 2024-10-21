import 'package:camera_app/ImageProcessor/ImageProcessor.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:ui' as ui;
import 'dart:typed_data'; // Import necessário para o Uint8List

class EditCarouselOptions extends StatefulWidget {
  final List<String> imagePaths;
  final String originalImagePath;
  final Function(ui.Image?) onImageProcessed;

  EditCarouselOptions({
    required this.imagePaths,
    required this.originalImagePath,
    required this.onImageProcessed,
  });

  @override
  _EditCarouselOptionsState createState() => _EditCarouselOptionsState();
}

class _EditCarouselOptionsState extends State<EditCarouselOptions> {
  int _selectedIndex = -1;
  ui.Image? _processedImage;
  bool _isLoading = false; // Variável para controlar o estado de carregamento

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20), // Bordas arredondadas
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CarouselSlider(
              options: CarouselOptions(
                height: 100,
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
                          _isLoading = true; // Inicia o carregamento
                        
                        });

                        String selectedHairImagePath = imagePath;

                        // Processar a imagem
                        ImageProcessor processor = ImageProcessor(
                          widget.originalImagePath,
                          selectedHairImagePath,
                        );

                        // Supondo que processImages() retorne Uint8List
                        Uint8List processedImageBytes =
                            await processor.processImages();

                        // Converter Uint8List para ui.Image
                        ui.Image processedImage =
                            await _uint8ListToUiImage(processedImageBytes);

                        setState(() {
                          _processedImage = processedImage;
                          widget.onImageProcessed(processedImage);
                          _isLoading = false; // Termina o carregamento
                        });
                      },
                      child: ClipOval(
                        child: Stack(
                          alignment: Alignment.center, // Centraliza o CircularProgressIndicator
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                image: DecorationImage(
                                  image: AssetImage(imagePath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              width: 100,
                            ),
                            if (_isLoading && _selectedIndex == index) // Exibe o CircularProgressIndicator apenas para a imagem selecionada
                              CircularProgressIndicator(),
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

  // Função auxiliar para converter Uint8List para ui.Image
  Future<ui.Image> _uint8ListToUiImage(Uint8List uint8List) async {
    final codec = await ui.instantiateImageCodec(uint8List);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}