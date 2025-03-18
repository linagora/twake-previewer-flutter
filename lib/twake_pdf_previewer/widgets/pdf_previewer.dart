import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfPreviewer extends StatelessWidget {
  const PdfPreviewer({
    super.key,
    required this.bytes,
    required this.controller,
    this.fileName,
    this.onTapOutside,
    this.onReady,
  });

  final Uint8List bytes;
  final PdfViewerController controller;
  final String? fileName;
  final VoidCallback? onTapOutside;
  final VoidCallback? onReady;

  static const double _minScale = 1;
  static const double _maxScale = 4;
  static const double _scrollbarWidth = 10;

  int? _calculateCurrentPageNumber(
    Rect visibleRect,
    List<Rect> pageRects,
    PdfViewerController controller,
  ) {
    if (pageRects.isEmpty) {
      return null;
    }

    if (pageRects.first.top == visibleRect.top) {
      return 1; // view at top
    }

    if (pageRects.last.bottom == visibleRect.bottom) {
      return pageRects.length; // view at bottom
    }

    final intersectRatios = <double>[];
    for (var i = 0; i < pageRects.length; i++) {
      final intersect = pageRects[i].intersect(visibleRect);
      if (intersect.isEmpty) {
        intersectRatios.add(0);
        continue;
      }

      final intersectRatio = (intersect.width * intersect.height) /
          (pageRects[i].width * pageRects[i].height);
      intersectRatios.add(intersectRatio);
    }
    final maxIntersectRatio = intersectRatios.reduce(max);
    return intersectRatios.indexOf(maxIntersectRatio) + 1;
  }

  PdfPageLayout _layoutPdf(
    BuildContext context,
    List<PdfPage> pages,
    PdfViewerParams params,
  ) {
    final viewHeight = MediaQuery.sizeOf(context).height;
    final width = pages.fold(0.0, (prev, page) => max(prev, page.width));
    final height = pages.fold(0.0, (prev, page) => max(prev, page.height));
    final ratio = viewHeight / max(width, height);
    final pageLayouts = <Rect>[];
    double top = params.margin;
    for (final page in pages) {
      pageLayouts.add(
        Rect.fromLTWH(
          0,
          top,
          page.width * ratio,
          page.height * ratio,
        ),
      );
      top += page.height * ratio + params.margin;
    }

    return PdfPageLayout(
      pageLayouts: pageLayouts,
      documentSize: Size(width * ratio, top),
    );
  }

  double get _tapOutSideZoneWidth {
    final documentWidth = controller.documentSize.width;
    final documentRenderWidth = documentWidth * controller.currentZoom;
    final viewSizeWidth = controller.viewSize.width;

    return viewSizeWidth > documentRenderWidth
        ? (viewSizeWidth - documentRenderWidth) / 2
        : 0;
  }

  @override
  Widget build(BuildContext context) {
    return PdfViewer.data(
      bytes,
      controller: controller,
      sourceName: fileName ?? 'file.pdf',
      params: PdfViewerParams(
        panAxis: PanAxis.vertical,
        scrollByMouseWheel: 0.5,
        backgroundColor: Colors.transparent,
        onViewerReady: (document, controller) {
          controller.setZoom(controller.centerPosition, 1);
          onReady?.call();
        },
        calculateCurrentPageNumber: _calculateCurrentPageNumber,
        minScale: _minScale,
        maxScale: _maxScale,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        onInteractionEnd: (details) {
          if (controller.currentZoom < _minScale) {
            controller.setZoom(
              controller.centerPosition,
              _minScale,
            );
          } else if (controller.currentZoom > _maxScale) {
            controller.setZoom(
              controller.centerPosition,
              _maxScale,
            );
          }
        },
        layoutPages: (pages, params) => _layoutPdf(
          context,
          pages,
          params,
        ),
        viewerOverlayBuilder: (_, __, ___) => [
          Positioned(
            left: 0,
            height: controller.documentSize.height,
            width: _tapOutSideZoneWidth,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onTapOutside,
              child: const IgnorePointer(
                child: SizedBox.expand(),
              ),
            ),
          ),
          Positioned(
            right: _scrollbarWidth,
            height: controller.documentSize.height,
            width: _tapOutSideZoneWidth - _scrollbarWidth,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onTapOutside,
              child: const IgnorePointer(
                child: SizedBox.expand(),
              ),
            ),
          ),
          PdfViewerScrollThumb(
            controller: controller,
            orientation: ScrollbarOrientation.right,
            thumbSize: const Size(_scrollbarWidth, 100),
            thumbBuilder: (_, __, ___, ____) => const ColoredBox(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
