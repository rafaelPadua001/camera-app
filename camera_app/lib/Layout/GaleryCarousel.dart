import 'package:flutter/material.dart';
import 'dart:io';

class GaleryCarousel extends StatelessWidget {
  final List<File> images;
  final int initialIndex;

  GaleryCarousel({required this.images, required this.initialIndex});

  @override
  Widget build(BuildContext contex) {
    return Scaffold(
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
