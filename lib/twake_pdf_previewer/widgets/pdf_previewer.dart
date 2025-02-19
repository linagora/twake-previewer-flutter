import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf_render/pdf_render_widgets.dart';

class PdfPreviewer extends StatefulWidget {
  const PdfPreviewer({
    super.key,
    required this.bytes,
    required this.controller,
    this.onError,
    this.onTapOutside,
  });

  final Uint8List bytes;
  final PdfViewerController controller;
  final void Function(dynamic error)? onError;
  final VoidCallback? onTapOutside;

  @override
  State<PdfPreviewer> createState() => _PdfPreviewerState();
}

class _PdfPreviewerState extends State<PdfPreviewer> {
  late final PdfViewerController _pdfViewerController;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = widget.controller;
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdfViewer.openData(
      widget.bytes,
      viewerController: _pdfViewerController,
      onError: widget.onError,
      params: PdfViewerParams(
        panAxis: PanAxis.vertical,
        scrollByMouseWheel: 0.5,
        layoutPages: (viewSize, pages) {
          List<Rect> rect = [];
          final viewWidth = viewSize.width;
          final viewHeight = viewSize.height;
          final maxHeight = pages.fold<double>(
              0.0, (maxHeight, page) => max(maxHeight, page.height));
          final maxWidth = pages.fold<double>(
              0.0, (maxWidth, page) => max(maxWidth, page.width));
          final ratio = viewHeight / max(maxHeight, maxWidth);
          var top = 0.0;
          double padding = 16.0;
          for (var page in pages) {
            final width = page.width * ratio;
            final height = page.height * ratio;
            final left =
                viewWidth > viewHeight ? (viewWidth / 2) - (width / 2) : 0.0;
            rect.add(Rect.fromLTWH(left, top, width, height));
            top += height + padding;
          }
          return rect;
        },
        onClickOutSidePageViewer: widget.onTapOutside,
      ),
    );
  }
}
