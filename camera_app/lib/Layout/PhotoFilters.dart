import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class FilteredImageWidget extends StatefulWidget {
  final File originalImage;
  final Uint8List? processedImage;
  final Function(String, double)
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
  final Map<String, bool> _expandedStates = {
    "Brightness & Contrast": false,
    "Saturation & Hue": false,
    "Exposure": false,
    "Others": false,
  };

  final Map<String, double> _sliderValues = {
    "Brightness": 0.0,
    "Contrast": 0.0,
    "Saturation": 0.0,
    "Hue": 0.0,
    "Exposure": 0.0,
    "Others": 0.0,
  };

  bool _isExpanded = false;


  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildCard("Brightness & Contrast", "Brightness", "Contrast"),
        _buildCard("Saturation & Hue", "Saturation", "Hue"),
        _buildCard("Exposure", "Exposure"),
      ],
    );
  }

  Widget _buildCard(String title, String label1, [String? label2]) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(title),
            trailing: IconButton(
              icon: Icon(_expandedStates[title]!
                  ? Icons.arrow_upward
                  : Icons.arrow_downward),
              onPressed: () {
                setState(() {
                  _expandedStates[title] = !_expandedStates[title]!;
                });
              },
            ),
          ),
          if (_expandedStates[title]!) ...[
            _buildSlider(label1),
            if(label2 != null) _buildSlider(label2),
          ],
        ],
      ),
    );
  }

  Widget _buildSlider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _sliderValues[label]!,
            min: -1.0,
            max: 1.0,
            divisions: 20,
            label: _sliderValues[label]!.toStringAsFixed(2),
            onChanged: (value) {
              setState(() {
                _sliderValues[label] = value;
              });
            },
            onChangeEnd: (value) {
              widget.onFilterChanged(
                  label, value); // Envia o nome do filtro e o valor atualizado
            },
          ),
        ],
      ),
    );
  }
}
