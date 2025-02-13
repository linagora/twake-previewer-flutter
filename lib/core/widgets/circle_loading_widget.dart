import 'package:flutter/material.dart';

class CircleLoadingWidget extends StatelessWidget {
  final double? size;
  final Color? color;
  final double? strokeWidth;
  final EdgeInsetsGeometry? padding;

  const CircleLoadingWidget({
    super.key,
    this.size,
    this.color,
    this.padding,
    this.strokeWidth,
  });

  static const double _defaultSize = 24;
  static const double _defaultStrokeWidth = 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      width: size ?? _defaultSize,
      height: size ?? _defaultSize,
      child: CircularProgressIndicator(
        color: color,
        strokeWidth: strokeWidth ?? _defaultStrokeWidth,
      ),
    );
  }
}
