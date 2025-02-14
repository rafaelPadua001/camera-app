import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class FilteredImageWidget extends StatefulWidget {
  final File originalImage;
  final Uint8List? processedImage;
  final Function(double)
      onFilterChanged; //callbar oara enviar os valores do sliders
  final Function(double) onContrastChanged;
  final Function(double) onSaturationChanged;
  final Function(double) onExposureChanged;
  final Function(double) onHueChanged;

  const FilteredImageWidget(
      {required this.originalImage,
      this.processedImage,
      required this.onFilterChanged,
      required this.onContrastChanged,
      required this.onSaturationChanged,
      required this.onExposureChanged,
      required this.onHueChanged});

  @override
  _FilteredImageWidgetState createState() => _FilteredImageWidgetState();
}

class _FilteredImageWidgetState extends State<FilteredImageWidget> {
  double _brightness = 0.0;
  double _contrast = 0.0;
  double _saturation = 0.0;
  double _exposure = 0.0;
  double _hue = 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 350,
      color: Colors.grey.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Flexible(
            child: SingleChildScrollView(
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
                  secondaryTrackValue: _saturation,
                  min: -1.0,
                  max: 1.0,
                  divisions: 20,
                  label: _contrast.toStringAsFixed(2),
                  onChanged: (value) {
                    setState(() {
                      _contrast = value;
                    });
                  },
                  onChangeEnd: (value) {
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
                    value: _saturation,
                    label: _saturation.toStringAsFixed(2),
                    onChanged: (double value) {
                      setState(() {
                        //_currentSliderThirdValue = value;
                        _saturation = value;
                      });
                    },
                    onChangeEnd: (double value) {
                      widget.onSaturationChanged(value);
                    }),
                Text(
                  'Exposure:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                    value: _exposure,
                    label: _exposure.toStringAsFixed(2),
                    onChanged: (double value) {
                      setState(() {
                        //_currentSliderThirdValue = value;
                        _exposure = value;
                      });
                    },
                    onChangeEnd: (double value) {
                      widget.onExposureChanged(value);
                    }),
                Text(
                  'Hue:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                    value: _hue,
                    label: _hue.toStringAsFixed(2),
                    onChanged: (double value) {
                      setState(() {
                        //_currentSliderThirdValue = value;
                        _hue = value;
                      });
                    },
                    onChangeEnd: (double value) {
                      widget.onHueChanged(value);
                    }),
              ],
            )),
          ),
        ],
      ),
    );
  }
}
