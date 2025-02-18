import 'package:flutter/material.dart';
import 'dart:io';

class GaleryCarousel extends StatelessWidget {
  final List<File> images;
  final int initialIndex;

  GaleryCarousel({required this.images, required this.initialIndex});

  @override
  Widget build(BuildContext contex) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.favorite_border_outlined),
            tooltip: 'Show anything',
            onPressed: (){
              ScaffoldMessenger.of(
                contex
              ).showSnackBar(
                const SnackBar(content: Text('this is snackbar'))
              );
            },
          )
        ]
      ),
      body: PageView.builder(
        itemCount: images.length,
        controller: PageController(initialPage: initialIndex),
        itemBuilder: (context, index) {
          return Center(
            child: Image.file(
              images[index],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}
