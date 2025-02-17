import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/top_bar_options.dart';
import 'package:twake_previewer_flutter/core/previewer_options/previewer_options.dart';
import 'package:twake_previewer_flutter/core/widgets/top_bar_widget.dart';

class TwakeImagePreviewer extends StatelessWidget {
  const TwakeImagePreviewer({
    super.key,
    this.bytes,
    this.errorBuilder,
    this.previewerOptions,
    this.topBarOptions,
  });

  final Uint8List? bytes;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final PreviewerOptions? previewerOptions;
  final TopBarOptions? topBarOptions;

  @override
  Widget build(BuildContext context) {
    final previewerChild = bytes == null
        ? const SizedBox()
        : Image.memory(
            bytes!,
            width: previewerOptions?.width,
            height: previewerOptions?.height,
            errorBuilder: errorBuilder,
          );

    final topBarChild = topBarOptions == null
        ? const SizedBox()
        : TopBarWidget(
            title: topBarOptions!.title,
            closeAction: topBarOptions!.onClose,
            closeTooltip: topBarOptions!.closeTooltip,
            downloadAction: topBarOptions!.onDownload,
            downloadTooltip: topBarOptions!.downloadTooltip,
            printAction: topBarOptions!.onPrint,
            printTooltip: topBarOptions!.printTooltip,
          );

    return Column(
      children: [
        topBarChild,
        Expanded(
          child: SingleChildScrollView(
            child: previewerChild,
          ),
        ),
      ],
    );
  }
}
