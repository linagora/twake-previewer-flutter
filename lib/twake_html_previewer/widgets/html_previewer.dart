import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:twake_previewer_flutter/core/utils/utils.dart';
import 'package:twake_previewer_flutter/twake_html_previewer/utils/html_templates.dart';
import 'package:twake_previewer_flutter/twake_html_previewer/utils/twake_dart_ui.dart';
import 'package:universal_html/html.dart';

class HtmlPreviewer extends StatefulWidget {
  final String contentHtml;
  final String contentClassName;
  final double widthContent;
  final double heightContent;
  final double minHeight;
  final TextDirection? direction;
  final String? styleCss;
  final String? scripts;
  final bool disableZoom;
  final bool hideScrollBar;

  /// Handler for mailto: links
  final void Function(Uri?)? mailtoDelegate;
  final void Function(Uri?)? onClickHyperLinkAction;

  // If widthContent is bigger than width of contentHtml, set this to true let widget able to resize to width of contentHtml
  final bool allowResizeToDocumentSize;

  final bool keepWidthWhileLoading;
  final void Function()? onLoaded;

  const HtmlPreviewer({
    super.key,
    required this.contentHtml,
    required this.contentClassName,
    required this.widthContent,
    required this.heightContent,
    required this.minHeight,
    this.direction,
    this.styleCss,
    this.scripts,
    this.disableZoom = true,
    this.hideScrollBar = true,
    this.mailtoDelegate,
    this.onClickHyperLinkAction,
    this.allowResizeToDocumentSize = true,
    this.keepWidthWhileLoading = false,
    this.onLoaded,
  });

  @override
  State<HtmlPreviewer> createState() => _HtmlPreviewerState();
}

class _HtmlPreviewerState extends State<HtmlPreviewer> {
  static const double _minWidth = 300;
  static const String _iframeOnLoadMessage = 'iframeHasBeenLoaded';
  static const String _onClickHyperLinkName = 'onClickHyperLink';

  /// The view ID for the IFrameElement. Must be unique.
  late String _createdViewId;

  /// The actual height of the content view, used to automatically set the height
  late double _actualHeight;

  /// The actual width of the content view, used to automatically set the width
  late double _actualWidth;

  String _htmlData = '';
  late final StreamSubscription<MessageEvent> _messageListener;
  bool _iframeLoaded = false;

  @override
  void initState() {
    super.initState();
    _actualHeight = widget.heightContent;
    _actualWidth = widget.widthContent;

    _setUpWeb();

    _messageListener = window.onMessage.listen((event) {
      var data = json.decode(event.data);

      if (data['view'] != _createdViewId) return;

      if (data['message'] == _iframeOnLoadMessage) {
        _iframeLoaded = true;
      }
      if (!_iframeLoaded) return;

      final dataType = data['type'];
      if (dataType == null || dataType is! String) return;

      if (dataType.contains('toDart: htmlHeight')) {
        final docHeight = data['height'] ?? _actualHeight;
        if (docHeight != null && mounted) {
          final scrollHeightWithBuffer = docHeight + 30.0;
          if (scrollHeightWithBuffer > widget.minHeight) {
            setState(() {
              _actualHeight = scrollHeightWithBuffer;
            });
          }
        }
        widget.onLoaded?.call();
      }

      if (dataType.contains('toDart: htmlWidth') &&
          !widget.keepWidthWhileLoading) {
        final docWidth = data['width'] ?? _actualWidth;
        if (docWidth != null && mounted) {
          if (docWidth > _minWidth && widget.allowResizeToDocumentSize) {
            setState(() {
              _actualWidth = docWidth;
            });
          }
        }
      }

      if (dataType.contains('toDart: OpenLink')) {
        final link = data['url'];
        if (link != null && mounted) {
          final urlString = link as String;
          if (urlString.startsWith('mailto:')) {
            widget.mailtoDelegate?.call(Uri.parse(urlString));
          }
        }
      }

      if (dataType.contains('toDart: $_onClickHyperLinkName')) {
        final link = data['url'] as String?;
        if (link != null && mounted) {
          widget.onClickHyperLinkAction?.call(Uri.parse(link));
        }
      }
    });
  }

  @override
  void dispose() {
    _messageListener.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HtmlPreviewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contentHtml != oldWidget.contentHtml ||
        widget.direction != oldWidget.direction) {
      _setUpWeb();
    }

    if (widget.heightContent != oldWidget.heightContent) {
      _actualHeight = widget.heightContent;
    }

    if (widget.widthContent != oldWidget.widthContent) {
      _actualWidth = widget.widthContent;
    }
  }

  String _generateHtmlDocument(String content) {
    final webViewActionScripts = HtmlTemplates.getWebViewActionScript(
      _createdViewId,
      iframeOnLoadMessage: _iframeOnLoadMessage,
      mailtoDelegateAvailable: widget.mailtoDelegate != null,
      hyperLinkClickHandlerAvailable: widget.onClickHyperLinkAction != null,
      onClickHyperLinkName: _onClickHyperLinkName,
    );

    final scriptsDisableZoom =
        widget.disableZoom ? HtmlTemplates.getDisableZoomScript() : '';

    final htmlTemplate = HtmlTemplates.generate(
      content: content,
      contentClassName: widget.contentClassName,
      minHeight: widget.minHeight,
      minWidth: _minWidth,
      styleCSS: widget.styleCss,
      javaScripts:
          webViewActionScripts + scriptsDisableZoom + (widget.scripts ?? ''),
      direction: widget.direction,
      hideScrollBar: widget.hideScrollBar,
    );

    return htmlTemplate;
  }

  void _setUpWeb() {
    _createdViewId = Utils.getRandString(10);
    _htmlData = _generateHtmlDocument(widget.contentHtml);

    final iframe = IFrameElement()
      ..width = _actualWidth.toString()
      ..height = _actualHeight.toString()
      ..srcdoc = _htmlData
      ..style.border = 'none'
      ..style.overflow = 'hidden'
      ..style.width = '100%'
      ..style.height = '100%';

    platformViewRegistry.registerViewFactory(_createdViewId, (_) => iframe);
  }

  @override
  Widget build(BuildContext context) {
    if (_htmlData.isEmpty) return const SizedBox();

    return SizedBox(
      height: _actualHeight,
      width: _actualWidth,
      child: HtmlElementView(
        key: ValueKey(_htmlData),
        viewType: _createdViewId,
      ),
    );
  }
}
