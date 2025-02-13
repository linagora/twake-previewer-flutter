import 'package:equatable/equatable.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/previewer_state.dart';

class PreviewerOptions extends Equatable {
  const PreviewerOptions({
    required this.previewerState,
    this.onError,
    this.errorMessage,
  });

  final PreviewerState previewerState;
  final void Function(dynamic error)? onError;
  final String? errorMessage;

  @override
  List<Object?> get props => [
        previewerState,
        onError,
        errorMessage,
      ];
}
