import 'dart:io';
import 'package:flutter/material.dart';

class FilteredImageWidget extends StatefulWidget {
  @override
  _FilteredImageWidgetState createState() => _FilteredImageWidgetState();
}

class _FilteredImageWidgetState extends State<FilteredImageWidget> {
  double _currentSliderPrimaryValue = 0.2;
  double _currentSliderSecondaryValue = 0.5;
  double _currentSliderThirdValue = 0.9;
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
            min: 0,
            max: 100,
            divisions: 100,
            secondaryTrackValue: _currentSliderSecondaryValue,
            label: _currentSliderPrimaryValue.round().toString(),
            onChanged: (double value) {
              setState(() {
                _currentSliderPrimaryValue = value;
              });
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
            min: 0,
            max: 100,
            divisions: 100,
            secondaryTrackValue: _currentSliderThirdValue,
            label: _currentSliderSecondaryValue.round().toString(),
            onChanged: (double value) {
              setState(() {
                _currentSliderSecondaryValue = value;
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
            min: 0,
            max: 100,
            divisions: 100,
            label: _currentSliderThirdValue.round().toString(),
            onChanged: (double value) {
              setState(() {
                _currentSliderThirdValue  = value;
              });
            },
          ),
          Center(
            child:  ElevatedButton(
            onPressed: (){
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
