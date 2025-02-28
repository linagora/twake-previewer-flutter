import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/loading_options.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/previewer_state.dart';
import 'package:twake_previewer_flutter/core/previewer_options/previewer_options.dart';
import 'package:twake_previewer_flutter/core/widgets/circle_loading_widget.dart';

class PreviewerTemplateWidget extends StatelessWidget {
  const PreviewerTemplateWidget({
    super.key,
    required this.child,
    this.previewerOptions,
    this.loadingOptions,
  });

  final PreviewerOptions? previewerOptions;
  final LoadingOptions? loadingOptions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return switch (previewerOptions?.previewerState) {
      PreviewerState.success => child,
      PreviewerState.loading => CircularPercentIndicator(
          percent: loadingOptions?.progress ?? 0.0,
          progressColor: loadingOptions?.progressColor,
          lineWidth: 4.0,
          backgroundColor: Colors.white,
          radius: 40,
          center: loadingOptions?.text == null
              ? null
              : Text(
                  loadingOptions!.text!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      PreviewerState.failure => Text(
          previewerOptions?.errorMessage ?? 'No preview available',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      _ => const CircleLoadingWidget(
          size: 80,
          strokeWidth: 4.0,
        )
    };
  }
}
