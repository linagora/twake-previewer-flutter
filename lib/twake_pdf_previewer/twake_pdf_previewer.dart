import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/loading_options.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/previewer_state.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/top_bar_options.dart';
import 'package:twake_previewer_flutter/core/previewer_options/previewer_options.dart';
import 'package:twake_previewer_flutter/core/widgets/circle_loading_widget.dart';
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
    final previewerChild = ValueListenableBuilder(
      valueListenable: _previewerState,
      builder: (context, previewerState, _) {
        if (previewerState == PreviewerState.success && widget.bytes != null) {
          return PdfPreviewer(
            bytes: widget.bytes!,
            controller: _pdfViewerController,
            fileName: widget.topBarOptions?.title,
            onTapOutside: widget.onTapOutside,
            onReady: () => setState(() => _pdfViewerIsReady = true),
          );
        } else if (previewerState == PreviewerState.loading) {
          return CircularPercentIndicator(
            percent: widget.loadingOptions?.progress ?? 0.0,
            progressColor: widget.loadingOptions?.progressColor,
            lineWidth: 4.0,
            backgroundColor: Colors.white,
            radius: 40,
            center: widget.loadingOptions?.text == null
                ? null
                : Text(
                    widget.loadingOptions!.text!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          );
        } else if (previewerState == PreviewerState.failure) {
          return Text(
            widget.previewerOptions.errorMessage ?? 'No preview available',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          );
        } else {
          return const CircleLoadingWidget(
            size: 80,
            strokeWidth: 4.0,
          );
        }
      },
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
      onKeyEvent: _handleKeyboardEventListener,
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

  void _handleKeyboardEventListener(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      widget.topBarOptions?.onClose?.call();
    }
  }
}
