import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/loading_options.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/top_bar_options.dart';
import 'package:twake_previewer_flutter/core/previewer_options/previewer_options.dart';
import 'package:twake_previewer_flutter/core/utils/utils.dart';
import 'package:twake_previewer_flutter/core/widgets/previewer_template_widget.dart';
import 'package:twake_previewer_flutter/core/widgets/top_bar_widget.dart';

class TwakeImagePreviewer extends StatefulWidget {
  const TwakeImagePreviewer({
    super.key,
    this.bytes,
    this.errorBuilder,
    this.previewerOptions,
    this.loadingOptions,
    this.topBarOptions,
    this.zoomable = false,
  });

  final Uint8List? bytes;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final PreviewerOptions? previewerOptions;
  final LoadingOptions? loadingOptions;
  final TopBarOptions? topBarOptions;
  final bool zoomable;

  @override
  State<TwakeImagePreviewer> createState() => _TwakeImagePreviewerState();
}

class _TwakeImagePreviewerState extends State<TwakeImagePreviewer> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget previewerChild = PreviewerTemplateWidget(
      previewerOptions: widget.previewerOptions,
      loadingOptions: widget.loadingOptions,
      child: widget.bytes == null
          ? const SizedBox()
          : Image.memory(
              widget.bytes!,
              width: widget.previewerOptions?.width,
              height: widget.previewerOptions?.height,
              errorBuilder: widget.errorBuilder,
            ),
    );

    if (widget.zoomable) {
      previewerChild = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.maybePop(context);
        },
        child: InteractiveViewer(
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // If this onTap is null, the parent GestureDetector's onTap will be triggered
              },
              child: previewerChild,
            ),
          ),
        ),
      );
    }

    final topBarChild = widget.topBarOptions == null
        ? const SizedBox()
        : TopBarWidget(
            title: widget.topBarOptions!.title,
            closeAction: widget.topBarOptions!.onClose,
            closeTooltip: widget.topBarOptions!.closeTooltip,
            downloadAction: widget.topBarOptions!.onDownload,
            downloadTooltip: widget.topBarOptions!.downloadTooltip,
            printAction: widget.topBarOptions!.onPrint,
            printTooltip: widget.topBarOptions!.printTooltip,
          );

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (value) {
        Utils.handleEscapeKey(value, widget.topBarOptions?.onClose);
      },
      child: Column(
        children: [
          topBarChild,
          Expanded(
            child: previewerChild,
          ),
        ],
      ),
    );
  }
}
