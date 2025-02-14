import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/loading_options.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/top_bar_options.dart';
import 'package:twake_previewer_flutter/core/previewer_options/previewer_options.dart';
import 'package:twake_previewer_flutter/core/widgets/top_bar_widget.dart';
import 'package:twake_previewer_flutter/twake_html_previewer/options/html_view_options.dart';
import 'package:twake_previewer_flutter/twake_html_previewer/widgets/html_previewer.dart';

class TwakeHtmlPreviewer extends StatefulWidget {
  final Uint8List? bytes;
  final PreviewerOptions previewerOptions;
  final HtmlViewOptions htmlViewOptions;
  final LoadingOptions? loadingOptions;
  final TopBarOptions? topBarOptions;

  const TwakeHtmlPreviewer({
    super.key,
    required this.bytes,
    required this.previewerOptions,
    required this.htmlViewOptions,
    this.loadingOptions,
    this.topBarOptions,
  });

  @override
  State<TwakeHtmlPreviewer> createState() => _TwakeHtmlPreviewerState();
}

class _TwakeHtmlPreviewerState extends State<TwakeHtmlPreviewer> {
  bool _isLoading = true;
  double _minHeight = 100;
  String _contentHtml = '';

  @override
  void initState() {
    super.initState();
    _contentHtml = widget.bytes == null ? '' : utf8.decode(widget.bytes!);
  }

  @override
  void didUpdateWidget(covariant TwakeHtmlPreviewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bytes != oldWidget.bytes) {
      setState(() {
        _contentHtml = widget.bytes == null ? '' : utf8.decode(widget.bytes!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewerChild = LayoutBuilder(
      builder: (context, constraint) {
        _minHeight = math.max(constraint.maxHeight, _minHeight);
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            HtmlPreviewer(
              contentHtml: _contentHtml,
              contentClass: widget.htmlViewOptions.contentClass,
              widthContent: widget.previewerOptions.width ?? 0,
              heightContent: widget.previewerOptions.height ?? 0,
              minHeight: _minHeight,
              allowResizeToDocumentSize:
                  widget.htmlViewOptions.allowResizeToDocumentSize,
              disableZoom: widget.htmlViewOptions.disableZoom,
              direction: widget.htmlViewOptions.direction,
              onClickHyperLinkAction:
                  widget.htmlViewOptions.onClickHyperLinkAction,
              mailtoDelegate: widget.htmlViewOptions.mailtoDelegate,
              keepWidthWhileLoading:
                  widget.htmlViewOptions.keepWidthWhileLoading,
              styleCss: widget.htmlViewOptions.styleCss,
              scripts: widget.htmlViewOptions.scripts,
              onLoaded: () => setState(() => _isLoading = false),
            ),
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                width: 30,
                height: 30,
                child: CupertinoActivityIndicator(
                  color: widget.loadingOptions?.progressColor,
                ),
              ),
          ],
        );
      },
    );

    final topBarChild = widget.topBarOptions == null
        ? const SizedBox()
        : TopBarWidget(
            title: widget.topBarOptions!.title,
            closeAction: widget.topBarOptions!.onClose,
            closeTooltip: widget.topBarOptions!.closeTooltip,
            printAction: widget.topBarOptions!.onPrint,
            printTooltip: widget.topBarOptions!.printTooltip,
            downloadAction: widget.topBarOptions!.onDownload,
            downloadTooltip: widget.topBarOptions!.downloadTooltip,
          );

    return Column(
      children: [
        topBarChild,
        Expanded(child: previewerChild),
      ],
    );
  }
}
