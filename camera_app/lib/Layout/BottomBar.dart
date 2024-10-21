import 'package:camera_app/Camera.dart';
import 'package:camera_app/main.dart';
import 'package:flutter/material.dart';
import '../Galery.dart';

class Bottombar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.redAccent,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            MyHomePage(title: 'Picture picker')));
              },
            ),
            IconButton(
              icon: Icon(Icons.image),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Galery(),
                    ));
              },
            ),
            IconButton(
                icon: Icon(Icons.photo_camera),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Camera(),
                      ));
                }),
            IconButton(
              icon: Icon(Icons.person),
              onPressed: null,
            ),
          ],
        ),
      ),
    );
  }
}
