import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'EditCarouselOptions.dart';

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
  Uint8List? processedImageBytes; // Nova variável para armazenar os bytes
  Offset _hairPosition = Offset(100, 100);
  bool isLoading = false; // Flag para controle de carregamento

  @override
  void initState() {
    super.initState();
    processedImage = widget.processedImage; // Inicializa a imagem processada
    if (processedImage != null) {
      _convertImageToBytes(
          processedImage!); // Converte para bytes se não for nula
    }
  }

  Future<void> _convertImageToBytes(ui.Image image) async {
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      setState(() {
        processedImageBytes =
            byteData.buffer.asUint8List(); // Armazena os bytes
      });
    }
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
            Colors.blue.withOpacity(0.0), // Cor inicial do gradiente
            Colors.purple.withOpacity(0.3), // Cor final do gradiente
          ],
          begin: Alignment.topLeft, // Direção do gradiente
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20), // Borda arredondada, se desejado
      ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            //  Text('Edit Dialog', style: TextStyle(color: Colors.white)),
            SizedBox(height: 10),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: 450,
                    maxWidth: 400,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    //  color: Colors.black.withOpacity(0.9),
                  ),
                  child: Stack(
                    alignment:
                        Alignment.center, // Centraliza o conteúdo no Stack
                    children: [
                      // Exibe a imagem processada ou a imagem original
                      processedImageBytes != null
                          ? Image.memory(
                              processedImageBytes!, // Exibe a imagem processada
                              fit: BoxFit
                                  .cover, // Ajusta o tamanho da imagem para cobrir o Container
                            )
                          : Image.file(
                              widget.image,
                              fit: BoxFit.cover,
                            ),
                      // Exibe o CircularProgressIndicator se isLoading for true
                      if (isLoading)
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blueAccent), // Cor do indicador
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
                ], // Adicione os caminhos das imagens aqui
                originalImagePath:
                    widget.image.path, // Passe o caminho da imagem original
                onImageProcessed: (ui.Image? newImage) async {
                  setState(() {
                    isLoading = true; // Inicia o carregamento
                  });
                  if (newImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Nenhum Rosto detectado...'),
                      ),
                    );
                  } else {
                    await _convertImageToBytes(
                        newImage); // Converte a nova imagem processada para bytes
                  }
                  setState(() {
                    processedImage = newImage; // Atualiza a imagem processada
                    isLoading = false; // Para o carregamento
                  });
                },
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // ... outros widgets ...
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                    SizedBox(width: 8), // Espaçamento entre os botões
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
