import 'package:flutter/material.dart';
import 'dart:io';

class RemoveDialog extends StatelessWidget {
  final File image;
  final VoidCallback onConfirm;
  final VoidCallback onReloadGallery; // Adicione este parâmetro

  RemoveDialog({
    required this.image,
    required this.onConfirm,
    required this.onReloadGallery, // Adicione este parâmetro
  });

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double dialogHeight = screenHeight * 0.6;

    return Dialog(
      backgroundColor: Colors.grey.withOpacity(0.3),
      child: SizedBox(
        height: dialogHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.cancel, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                Text('Remove Dialog'),
                IconButton(
                  icon: Icon(Icons.check_circle, color: Colors.white),
                  onPressed: () {
                    onConfirm(); // Chama a função de confirmação
                    onReloadGallery(); // Chama a função para recarregar a galeria
                    Navigator.of(context).pop(); // Fecha o diálogo
                  },
                ),
              ],
            ),
            SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Image.file(image, fit: BoxFit.cover),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
