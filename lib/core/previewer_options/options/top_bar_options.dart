import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class TopBarOptions extends Equatable {
  final String title;
  final VoidCallback? onClose;
  final VoidCallback? onPrint;
  final VoidCallback? onDownload;

  const TopBarOptions({
    required this.title,
    this.onClose,
    this.onPrint,
    this.onDownload,
  });

  @override
  List<Object?> get props => [title, onClose, onPrint, onDownload];
}
