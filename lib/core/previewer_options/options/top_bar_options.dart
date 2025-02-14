import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class TopBarOptions extends Equatable {
  final String title;
  final VoidCallback? onClose;
  final String? closeTooltip;
  final VoidCallback? onPrint;
  final String? printTooltip;
  final VoidCallback? onDownload;
  final String? downloadTooltip;

  const TopBarOptions({
    required this.title,
    this.onClose,
    this.closeTooltip,
    this.onPrint,
    this.printTooltip,
    this.onDownload,
    this.downloadTooltip,
  });

  @override
  List<Object?> get props => [
        title,
        onClose,
        closeTooltip,
        onPrint,
        printTooltip,
        onDownload,
        downloadTooltip,
      ];
}
