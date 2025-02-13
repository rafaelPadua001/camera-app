import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class FilteredImageWidget extends StatefulWidget {
  final File originalImage;
  final Uint8List? processedImage;
  final Function(double)
      onFilterChanged; //callbar oara enviar os valores do sliders

  const FilteredImageWidget({
    required this.originalImage,
    this.processedImage,
    required this.onFilterChanged,
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
              value: _currentSliderPrimaryValue,
              secondaryTrackValue: _currentSliderSecondaryValue,
              label: _currentSliderPrimaryValue.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _currentSliderPrimaryValue = value;
                  _brightness = value.clamp(-1.0, 1.0);
                });
              },
              onChangeEnd: (double value) {
                // Chama a função apenas quando o usuário soltar o Slider
                widget.onFilterChanged(_brightness);
                
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
              value: _currentSliderSecondaryValue,
              secondaryTrackValue: _currentSliderThirdValue,
              label: _currentSliderSecondaryValue.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _currentSliderSecondaryValue = value.clamp(-1.0, 1.0);
                });
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
              min: -1.0,
              max: 1.0,
              divisions: 100,
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
