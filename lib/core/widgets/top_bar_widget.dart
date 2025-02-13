import 'package:flutter/material.dart';

class TopBarWidget extends StatelessWidget {
  final String title;
  final VoidCallback? closeAction;
  final String? closeTooltip;
  final VoidCallback? printAction;
  final String? printTooltip;
  final VoidCallback? downloadAction;
  final String? downloadTooltip;

  const TopBarWidget({
    super.key,
    required this.title,
    this.closeAction,
    this.closeTooltip,
    this.printAction,
    this.printTooltip,
    this.downloadAction,
    this.downloadTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 52,
      color: Colors.black.withOpacity(0.3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: closeAction,
            padding: const EdgeInsets.all(8),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
            focusColor: Colors.black.withOpacity(0.3),
            hoverColor: Colors.black.withOpacity(0.3),
            tooltip: closeTooltip,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (printAction != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: IconButton(
                onPressed: printAction,
                padding: const EdgeInsets.all(8),
                icon: const Icon(
                  Icons.print,
                  color: Colors.white,
                  size: 24,
                ),
                focusColor: Colors.black.withOpacity(0.3),
                hoverColor: Colors.black.withOpacity(0.3),
                tooltip: printTooltip,
              ),
            ),
          if (downloadAction != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: IconButton(
                onPressed: downloadAction,
                padding: const EdgeInsets.all(8),
                icon: const Icon(
                  Icons.download,
                  color: Colors.white,
                  size: 24,
                ),
                focusColor: Colors.black.withOpacity(0.3),
                hoverColor: Colors.black.withOpacity(0.3),
                tooltip: downloadTooltip,
              ),
            )
        ],
      ),
    );
  }
}
