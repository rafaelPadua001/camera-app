import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import '../Galery.dart';

class Camera extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _requestCameraPermission(context);
    return Scaffold(
      body: Center(
        child: Text('Verificando permissões...'),
      ),
    );
  }

  void _requestCameraPermission(BuildContext context) async {
    PermissionStatus status = await Permission.camera.request();
    if (status.isGranted) {
      print('Permissão de camera concedida !');

      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
       // Voltar para a galeria e recarregar as imagens
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Galery()
        )
      ).then((_) {
        // Opcional: se Galery tem um método para recarregar as imagens
        // Você pode usar um método estático ou um Provider para gerenciar estado
        // Galery()._loadImages(); // Isso depende da estrutura que você tem
      });
    } else if (status.isDenied) {
      print('Permissaõ de camera Negada');
    } else if (status.isPermanentlyDenied) {
      print(
          'Permissão de camera permanentemente negada. Vá para as configurações.');
      openAppSettings();
    }
  }
}
