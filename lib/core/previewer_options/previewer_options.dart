import 'package:equatable/equatable.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/previewer_state.dart';

class PreviewerOptions extends Equatable {
  const PreviewerOptions({
    this.previewerState = PreviewerState.idle,
    this.onError,
    this.errorMessage,
    this.width,
    this.height,
  });

  final PreviewerState previewerState;
  final void Function(dynamic error)? onError;
  final String? errorMessage;
  final double? width;
  final double? height;

  @override
  List<Object?> get props => [
        previewerState,
        onError,
        errorMessage,
        width,
        height,
      ];
}
