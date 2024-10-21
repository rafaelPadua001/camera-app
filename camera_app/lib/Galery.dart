import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../Layout/RemoveDialog.dart';
import '../Layout/EditDialog.dart';

class Galery extends StatefulWidget {
  @override
  _GaleryState createState() => _GaleryState();
}

class _GaleryState extends State<Galery> {
  List<File> _images = []; // Lista para armazenar as imagens capturadas
  ui.Image? processedImage; 

  @override
  void initState() {
    super.initState();
    _loadImages(); // Carrega as imagens ao inicializar o widget
  }

  Future<void> _loadImages() async {
    final Directory directory =
        await getTemporaryDirectory(); // Use getTemporaryDirectory para acessar o cache
    final String path = directory.path;

    // Carrega as imagens do diretório
    final List<FileSystemEntity> files = Directory(path).listSync();

    // Filtra apenas arquivos que são imagens (JPEG ou PNG, por exemplo)
    setState(() {
      _images = files
          .where((file) =>
              file is File &&
              (file.path.endsWith('.jpg') || file.path.endsWith('.png')))
          .map((file) => file as File)
          .toList();
    });
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index); // Remove a imagem da lista
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use um Scaffold para melhor estruturação
      body: Center(
        child: _images.isEmpty
            ? Text("Nenhuma imagem encontrada.")
            : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                ),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onLongPress: () {
                      _showOptionsMenu(context, index);
                    },
                    child: Image.file(
                      _images[index],
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.share),
                title: Text('Share'),
                onTap: () {
                  Navigator.pop(context); // Fecha o menu
                  // Adicione a funcionalidade de compartilhamento aqui
                },
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                onTap: () {
                  Navigator.pop(context); // Fecha o menu
                  _showEditDialog(context, _images[index], processedImage, index);
                  // Adicione a funcionalidade de mostrar informações sobre a imagem aqui
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Remove'),
                onTap: () {
                  Navigator.pop(context); // Fecha o menu
                  _showRemoveDialog(context, _images[index], index);
                },
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('Properties'),
                onTap: () {
                  Navigator.pop(context); // Fecha o menu
                  // Adicione a funcionalidade de mostrar informações sobre a imagem aqui
                },
              ),
            ],
          ),
        );
      },
    );
  }

void _showEditDialog(
    BuildContext context, File image, ui.Image? processedImage, int index) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return EditDialog(
        image: image,
        processedImage: processedImage, // Passa a imagem processada aqui
      );
    },
  );
}


  void _showRemoveDialog(BuildContext context, File image, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RemoveDialog(
          image: image,
          onConfirm: () async {
            await image.delete(); // Deleta a imagem
            _removeImage(index); // Remove a imagem da lista
          },
          onReloadGallery: () {
            _loadImages(); // Chama a função para recarregar as imagens
          },
        );
      },
    );
  }
}
