import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/previewer_state.dart';
import 'package:twake_previewer_flutter/core/previewer_options/previewer_options.dart';
import 'package:twake_previewer_flutter/twake_pdf_previewer/twake_pdf_previewer.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Uint8List? bytes;
  String? extension;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ExampleViewer(
          bytes: bytes,
          extension: extension,
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.file_open),
          onPressed: () {
            FilePicker.platform.pickFiles().then(
              (value) {
                if (value == null || value.files.isEmpty) return;

                setState(() {
                  bytes = value.files.single.bytes;
                  extension = value.files.single.extension;
                });
              },
              onError: (error, stackTrace) {
                debugPrintStack(stackTrace: stackTrace);
              },
            );
          },
        ),
      ),
    );
  }
}

class ExampleViewer extends StatelessWidget {
  const ExampleViewer({super.key, this.bytes, this.extension});

  final Uint8List? bytes;
  final String? extension;

  @override
  Widget build(BuildContext context) {
    if (bytes == null) return const Placeholder();

    if (extension == 'pdf') {
      return TwakePdfPreviewer(
        previewerOptions: PreviewerOptions(
          previewerState: PreviewerState.success,
          onError: (error) {
            debugPrint('error: $error');
          },
        ),
        bytes: bytes,
        onTapOutside: () {
          debugPrint('onTapOutside');
        },
      );
    }

    return const Placeholder();
  }
}
