import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerScreen extends StatefulWidget {
  final Function(Color) onColorSlected;

  const ColorPickerScreen({Key? key, required this.onColorSlected}) : super(key: key);

  @override
  _ColorPickerScreenState createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  Color _currentColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SlidePicker(
            pickerColor: _currentColor,
            onColorChanged: (Color color) {
              setState(() {
                _currentColor = color;
              });
            },
            enableAlpha: true,
            displayThumbColor: true,
            showParams: true,
            showIndicator: true,
            indicatorBorderRadius:
                const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          const SizedBox(height: 1),
          ElevatedButton(
            onPressed: (){
              // print('Cor Aceita: $_currentColor');
              widget.onColorSlected(_currentColor);

            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
