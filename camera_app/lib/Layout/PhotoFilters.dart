import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class FilteredImageWidget extends StatefulWidget {
  final File originalImage;
  final Uint8List? processedImage;
  final Function(double)
      onFilterChanged; //callbar oara enviar os valores do sliders
  final Function(double) onContrastChanged;

  const FilteredImageWidget({
    required this.originalImage,
    this.processedImage,
    required this.onFilterChanged,
    required this.onContrastChanged,
  });

  @override
  _FilteredImageWidgetState createState() => _FilteredImageWidgetState();
}

class _FilteredImageWidgetState extends State<FilteredImageWidget> {
  double _currentSliderPrimaryValue = 0.2;
  double _currentSliderSecondaryValue = 0.5;
  double _currentSliderThirdValue = 0.9;

  //brightness initial value
  double _brightness = 1.0;
  double _contrast = 0.0;
  // Função para criar uma lista de filtros personalizados

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 250,
      color: Colors.grey.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Brightness:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: _brightness,
              secondaryTrackValue: _contrast,
              min: -1.0,
              max: 1.0,
              divisions: 20,
              label: _brightness.toStringAsFixed(2),
              onChanged: (value) {
                setState(() {
                  _brightness = value;
                });
              },
              onChangeEnd: (value) {
                // Chama a função apenas quando o usuário soltar o Slider
                widget.onFilterChanged(value);
              },
            ),
            Text(
              'Contrast:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: _contrast,
              secondaryTrackValue: _currentSliderThirdValue,
              min: -1.0,
              max: 1.0,
              divisions: 20,
              label: _contrast.toStringAsFixed(2),
              onChanged: (value) {
                setState(() {
                  _contrast = value;
                });
              },
              onChangeEnd: (value){
                widget.onContrastChanged(value);
              },
            ),
            Text(
              'Saturation:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: _currentSliderThirdValue,
              label: _currentSliderThirdValue.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _currentSliderThirdValue = value;
                });
              },
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  print('Botão salvar pressionado');
                },
                child: Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
