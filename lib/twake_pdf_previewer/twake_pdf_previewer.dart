import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/loading_options.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/previewer_state.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/top_bar_options.dart';
import 'package:twake_previewer_flutter/core/previewer_options/previewer_options.dart';
import 'package:twake_previewer_flutter/core/utils/utils.dart';
import 'package:twake_previewer_flutter/core/widgets/previewer_template_widget.dart';
import 'package:twake_previewer_flutter/core/widgets/top_bar_widget.dart';
import 'package:twake_previewer_flutter/twake_pdf_previewer/widgets/pdf_pagination_widget.dart';
import 'package:twake_previewer_flutter/twake_pdf_previewer/widgets/pdf_previewer.dart';

typedef DownloadPDFFileAction = Function(Uint8List bytes, String fileName);
typedef PrintPDFFileAction = Function(Uint8List bytes, String fileName);

class TwakePdfPreviewer extends StatefulWidget {
  const TwakePdfPreviewer({
    super.key,
    required this.previewerOptions,
    this.bytes,
    this.loadingOptions,
    this.topBarOptions,
    this.onTapOutside,
  });

  final PreviewerOptions previewerOptions;
  final Uint8List? bytes;
  final LoadingOptions? loadingOptions;
  final TopBarOptions? topBarOptions;
  final VoidCallback? onTapOutside;

  @override
  State<TwakePdfPreviewer> createState() => _TwakePdfPreviewerState();
}

class _TwakePdfPreviewerState extends State<TwakePdfPreviewer> {
  late ValueNotifier<PreviewerState> _previewerState;
  final _pdfViewerController = PdfViewerController();
  final _keyboardFocusNode = FocusNode();
  bool _pdfViewerIsReady = false;

  @override
  void initState() {
    super.initState();
    _previewerState = ValueNotifier(widget.previewerOptions.previewerState);
  }

  @override
  void didUpdateWidget(covariant TwakePdfPreviewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewerOptions.previewerState !=
            widget.previewerOptions.previewerState &&
        widget.previewerOptions.previewerState != _previewerState.value) {
      _previewerState = ValueNotifier(widget.previewerOptions.previewerState);
    }
  }

  @override
  void dispose() {
    _previewerState.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewerChild = PreviewerTemplateWidget(
      previewerOptions: widget.previewerOptions,
      loadingOptions: widget.loadingOptions,
      child: PdfPreviewer(
        bytes: widget.bytes ?? Uint8List.fromList([]),
        controller: _pdfViewerController,
        fileName: widget.topBarOptions?.title,
        onTapOutside: widget.onTapOutside,
        onReady: () => setState(() => _pdfViewerIsReady = true),
      ),
    );

    final topBarChild = ValueListenableBuilder(
      valueListenable: _previewerState,
      builder: (context, previewerState, child) {
        if (previewerState != PreviewerState.success ||
            widget.topBarOptions == null) {
          return child ?? const SizedBox();
        }

        return TopBarWidget(
          title: widget.topBarOptions!.title,
          closeAction: widget.topBarOptions!.onClose,
          printAction: widget.topBarOptions!.onPrint,
          downloadAction: widget.topBarOptions!.onDownload,
        );
      },
      child: TopBarWidget(
        title: widget.topBarOptions?.title ?? '',
        closeAction: widget.topBarOptions?.onClose,
      ),
    );

    final paginationChild = _pdfViewerIsReady
        ? PdfPaginationWidget(
            pdfViewerController: _pdfViewerController,
          )
        : const SizedBox.shrink();

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (value) {
        Utils.handleEscapeKey(value, widget.topBarOptions?.onClose);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          previewerChild,
          Align(
            alignment: AlignmentDirectional.topCenter,
            child: topBarChild,
          ),
          Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: paginationChild,
          ),
        ],
      ),
    );
  }
}
