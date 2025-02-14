import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

class HtmlViewOptions extends Equatable {
  final String contentClass;
  final TextDirection? direction;
  final String? styleCss;
  final String? scripts;
  final bool disableZoom;
  final void Function(Uri?)? mailtoDelegate;
  final void Function(Uri?)? onClickHyperLinkAction;
  final bool allowResizeToDocumentSize;
  final bool keepWidthWhileLoading;

  const HtmlViewOptions({
    required this.contentClass,
    this.direction,
    this.styleCss,
    this.scripts,
    this.disableZoom = true,
    this.mailtoDelegate,
    this.onClickHyperLinkAction,
    this.allowResizeToDocumentSize = true,
    this.keepWidthWhileLoading = false,
  });

  @override
  List<Object?> get props => [
        contentClass,
        direction,
        styleCss,
        scripts,
        disableZoom,
        mailtoDelegate,
        onClickHyperLinkAction,
        allowResizeToDocumentSize,
        keepWidthWhileLoading,
      ];
}
