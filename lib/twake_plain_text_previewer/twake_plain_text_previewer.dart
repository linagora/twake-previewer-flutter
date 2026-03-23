import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:twake_previewer_flutter/core/constants/supported_charset.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/loading_options.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/previewer_state.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/top_bar_options.dart';
import 'package:twake_previewer_flutter/core/previewer_options/previewer_options.dart';
import 'package:twake_previewer_flutter/core/utils/default_text_decoder.dart';
import 'package:twake_previewer_flutter/core/utils/text_decoder.dart';
import 'package:twake_previewer_flutter/core/utils/utils.dart';
import 'package:twake_previewer_flutter/core/widgets/previewer_template_widget.dart';
import 'package:twake_previewer_flutter/core/widgets/top_bar_widget.dart';

class TwakePlainTextPreviewer extends StatefulWidget {
  const TwakePlainTextPreviewer({
    super.key,
    required this.bytes,
    this.supportedCharset,
    this.previewerOptions,
    this.topBarOptions,
    this.loadingOptions,
    this.textDecoder = const DefaultTextDecoder(),
  });

  final SupportedCharset? supportedCharset;
  final Uint8List? bytes;
  final PreviewerOptions? previewerOptions;
  final TopBarOptions? topBarOptions;
  final LoadingOptions? loadingOptions;
  final TextDecoder textDecoder;

  @override
  State<TwakePlainTextPreviewer> createState() =>
      _TwakePlainTextPreviewerState();
}

class _TwakePlainTextPreviewerState extends State<TwakePlainTextPreviewer> {
  String text = '';
  final _focusNode = FocusNode();
  late final TextDecoder _decoder;
  PreviewerState? _previewerState;

  @override
  void initState() {
    super.initState();
    _previewerState = widget.previewerOptions?.previewerState;
    _decoder = widget.textDecoder;

    final result = _buildPreviewText(widget.bytes);

    if (result != null) {
      text = result;
    } else {
      _previewerState = PreviewerState.failure;
    }
  }

  String? _buildPreviewText(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return null;

    try {
      final charset = widget.supportedCharset ?? _decoder.detectCharset(bytes);

      return _decoder.decode(bytes: bytes, charset: charset);
    } catch (_) {
      return null;
    }
  }

  @override
  void didUpdateWidget(covariant TwakePlainTextPreviewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.previewerOptions?.previewerState != _previewerState) {
      _previewerState = widget.previewerOptions?.previewerState;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewerChild = PreviewerTemplateWidget(
      previewerOptions: widget.previewerOptions,
      loadingOptions: widget.loadingOptions,
      child: Container(
        color: Colors.white,
        width: widget.previewerOptions?.width,
        height: widget.previewerOptions?.height,
        padding: const EdgeInsets.all(16),
        child: SelectableText(text),
      ),
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
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.maybePop(context);
              },
              child: Center(
                child: SingleChildScrollView(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      // If this onTap is null, the parent GestureDetector's onTap will be triggered
                    },
                    child: previewerChild,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
