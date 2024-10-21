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
    return AlertDialog(
      backgroundColor: Colors.grey.withOpacity(0.8),
      title: const Text('Remove Dialog'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text('Remove this image? ${image.path.split('/').last}'),
            SizedBox(height: 30),
            Image.file(image, fit: BoxFit.cover),
            Text('Would you like to remove this image?'),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Ok'),
          onPressed: () {
            onConfirm(); // Chama a função de confirmação
            onReloadGallery(); // Chama a função para recarregar a galeria
            Navigator.of(context).pop(); // Fecha o diálogo
          },
        ),
      ],
    );
  }
}
