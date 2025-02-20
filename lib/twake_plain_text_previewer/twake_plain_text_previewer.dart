import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:twake_previewer_flutter/core/constants/supported_charset.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/top_bar_options.dart';
import 'package:twake_previewer_flutter/core/previewer_options/previewer_options.dart';
import 'package:twake_previewer_flutter/core/widgets/top_bar_widget.dart';

class TwakePlainTextPreviewer extends StatefulWidget {
  const TwakePlainTextPreviewer({
    super.key,
    required this.supportedCharset,
    this.bytes,
    this.previewerOptions,
    this.topBarOptions,
  });

  final SupportedCharset supportedCharset;
  final Uint8List? bytes;
  final PreviewerOptions? previewerOptions;
  final TopBarOptions? topBarOptions;

  @override
  State<TwakePlainTextPreviewer> createState() =>
      _TwakePlainTextPreviewerState();
}

class _TwakePlainTextPreviewerState extends State<TwakePlainTextPreviewer> {
  String text = '';

  @override
  void initState() {
    super.initState();
    if (widget.bytes != null) {
      text = switch (widget.supportedCharset) {
        SupportedCharset.ascii => ascii.decode(widget.bytes!),
        SupportedCharset.latin1 => latin1.decode(widget.bytes!),
        _ => utf8.decode(widget.bytes!),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewerChild = Container(
      color: Colors.white,
      width: widget.previewerOptions?.width,
      height: widget.previewerOptions?.height,
      child: Text(text),
    );

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

    return Column(
      children: [
        topBarChild,
        Expanded(
          child: SingleChildScrollView(child: previewerChild),
        ),
      ],
    );
  }
}
