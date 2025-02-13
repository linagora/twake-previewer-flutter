# Twake Previewer Flutter

A Flutter web application for previewing various file formats.

## Current Features

- **PDF Preview:** View PDF files directly in your web browser.

## Planned Features

- **HTML Preview:** Render HTML content within the application.
- **EML Preview:** Display the contents of email files (.eml).
- **Image Preview:** View various image formats (e.g., PNG, JPG, GIF).
- **Plain Text Preview:** Display the content of plain text files (.txt).
- **Markdown Preview:** Render Markdown documents for easy viewing.

## Platform Support

- **Web:** Currently, all preview functionalities are only available on the web platform. Future platform support may be considered.

## Getting Started

- Add this right above `<script src="flutter_bootstrap.js" async></script>`:

```html
<!-- IMPORTANT: load pdfjs files -->
<script
  src="https://cdn.jsdelivr.net/npm/pdfjs-dist@3.4.120/build/pdf.min.js"
  type="text/javascript"
></script>
<script type="text/javascript">
  pdfjsLib.GlobalWorkerOptions.workerSrc =
    "https://cdn.jsdelivr.net/npm/pdfjs-dist@3.4.120/build/pdf.worker.min.js";
  pdfRenderOptions = {
    // where cmaps are downloaded from
    cMapUrl: "https://cdn.jsdelivr.net/npm/pdfjs-dist@3.4.120/cmaps/",
    // The cmaps are compressed in the case
    cMapPacked: true,
    // any other options for pdfjsLib.getDocument.
    // params: {}
  };
</script>
```

## Example

```dart
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
      );
    }

    return const Placeholder();
  }
}
```
