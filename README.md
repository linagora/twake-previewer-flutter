# Twake Previewer Flutter

A Flutter web application for previewing various file formats.

## Current Features

- **PDF Preview:** View PDF files directly in your web browser.
- **HTML Preview:** Render HTML content within the application.
- **Image Preview:** View various image formats (e.g., PNG, JPG, GIF).
- **Plain Text Preview:** Display the content of plain text files (.txt).

## Planned Features

- **Markdown Preview:** Render Markdown documents for easy viewing.

## Platform Support

- **Web:** Currently, all preview functionalities are only available on the web platform. Future platform support may be considered.

## Example

```dart
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:twake_previewer_flutter/core/constants/supported_charset.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/previewer_state.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/top_bar_options.dart';
import 'package:twake_previewer_flutter/core/previewer_options/previewer_options.dart';
import 'package:twake_previewer_flutter/twake_html_previewer/options/html_view_options.dart';
import 'package:twake_previewer_flutter/twake_html_previewer/twake_html_previewer.dart';
import 'package:twake_previewer_flutter/twake_image_previewer/twake_image_previewer.dart';
import 'package:twake_previewer_flutter/twake_pdf_previewer/twake_pdf_previewer.dart';
import 'package:twake_previewer_flutter/twake_plain_text_previewer/twake_plain_text_previewer.dart';

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
        floatingActionButton: PointerInterceptor(
          child: FloatingActionButton(
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

    if (extension == 'html') {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: TwakeHtmlPreviewer(
              bytes: bytes,
              previewerOptions: PreviewerOptions(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              ),
              htmlViewOptions: const HtmlViewOptions(
                contentClassName: 'sample-content',
              ),
              topBarOptions: TopBarOptions(
                title: 'Some title',
                onClose: () => debugPrint('onClose'),
              ),
            ),
          );
        },
      );
    }

    if (['png', 'jpg', 'jpeg', 'gif'].contains(extension)) {
      return Center(
        child: TwakeImagePreviewer(
          bytes: bytes,
          previewerOptions: const PreviewerOptions(width: 600),
          topBarOptions: TopBarOptions(
            title: 'Some title',
            onClose: () => debugPrint('onClose'),
          ),
        ),
      );
    }

    if (extension == 'txt') {
      return Center(
        child: TwakePlainTextPreviewer(
          supportedCharset: SupportedCharset.utf8,
          bytes: bytes,
          previewerOptions: const PreviewerOptions(width: 600),
          topBarOptions: TopBarOptions(
            title: 'Some title',
            onClose: () => debugPrint('onClose'),
          ),
        ),
      );
    }

    return const Placeholder();
  }
}
```
