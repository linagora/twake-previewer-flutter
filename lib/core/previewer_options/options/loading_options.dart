import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class LoadingOptions extends Equatable {
  const LoadingOptions({
    this.progress = 0.0,
    this.progressColor,
    this.text,
  });

  final double progress;
  final Color? progressColor;
  final String? text;

  @override
  List<Object?> get props => [progress, progressColor, text];
}
