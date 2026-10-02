import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:twake_previewer_flutter/core/previewer_options/options/previewer_state.dart';
import 'package:twake_previewer_flutter/core/previewer_options/previewer_options.dart';
import 'package:twake_previewer_flutter/core/widgets/previewer_template_widget.dart';
import 'package:twake_previewer_flutter/twake_pdf_previewer/twake_pdf_previewer.dart';
import 'package:twake_previewer_flutter/twake_pdf_previewer/widgets/pdf_previewer.dart';

class _FakePdfViewerController extends PdfViewerController {
  final dests = <PdfDest?>[];

  @override
  Future<bool> goToDest(
    PdfDest? dest, {
    Duration duration = const Duration(milliseconds: 200),
  }) async {
    dests.add(dest);
    return true;
  }
}

const _linkRects = [PdfRect(0, 10, 10, 0)];
const _dest = PdfDest(2, PdfDestCommand.fit, null);

/// Builds [previewer] without mounting the pdfrx viewer and returns the
/// link tap handler it gives to pdfrx.
Future<void Function(PdfLink)> _pumpLinkTapHandler(
  WidgetTester tester,
  PdfPreviewer previewer,
) async {
  late PdfViewer viewer;
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        viewer = previewer.build(context) as PdfViewer;
        return const SizedBox.shrink();
      },
    ),
  );
  return viewer.params.linkHandlerParams!.onLinkTap;
}

Future<void> _urlLinkIsForwardedToOnLinkTap(WidgetTester tester) async {
  final controller = _FakePdfViewerController();
  final tappedUris = <Uri>[];
  final onLinkTap = await _pumpLinkTapHandler(
    tester,
    PdfPreviewer(
      bytes: Uint8List(0),
      controller: controller,
      onLinkTap: tappedUris.add,
    ),
  );

  onLinkTap(PdfLink(_linkRects, url: Uri.parse('https://example.com/a?b=c')));

  expect(tappedUris, [Uri.parse('https://example.com/a?b=c')]);
  expect(controller.dests, isEmpty);
}

Future<void> _destLinkNavigatesInsideDocument(WidgetTester tester) async {
  final controller = _FakePdfViewerController();
  final tappedUris = <Uri>[];
  final onLinkTap = await _pumpLinkTapHandler(
    tester,
    PdfPreviewer(
      bytes: Uint8List(0),
      controller: controller,
      onLinkTap: tappedUris.add,
    ),
  );

  onLinkTap(const PdfLink(_linkRects, dest: _dest));

  expect(controller.dests, [same(_dest)]);
  expect(tappedUris, isEmpty);
}

Future<void> _linkWithUrlAndDestOnlyCallsOnLinkTap(WidgetTester tester) async {
  final controller = _FakePdfViewerController();
  final tappedUris = <Uri>[];
  final onLinkTap = await _pumpLinkTapHandler(
    tester,
    PdfPreviewer(
      bytes: Uint8List(0),
      controller: controller,
      onLinkTap: tappedUris.add,
    ),
  );

  onLinkTap(
    PdfLink(_linkRects, url: Uri.parse('https://example.com'), dest: _dest),
  );

  expect(tappedUris, [Uri.parse('https://example.com')]);
  expect(controller.dests, isEmpty);
}

Future<void> _urlLinkWithoutOnLinkTapDoesNothing(WidgetTester tester) async {
  final controller = _FakePdfViewerController();
  final onLinkTap = await _pumpLinkTapHandler(
    tester,
    PdfPreviewer(bytes: Uint8List(0), controller: controller),
  );

  onLinkTap(PdfLink(_linkRects, url: Uri.parse('https://example.com')));

  expect(controller.dests, isEmpty);
}

Future<void> _linkWithoutUrlNorDestDoesNothing(WidgetTester tester) async {
  final controller = _FakePdfViewerController();
  final tappedUris = <Uri>[];
  final onLinkTap = await _pumpLinkTapHandler(
    tester,
    PdfPreviewer(
      bytes: Uint8List(0),
      controller: controller,
      onLinkTap: tappedUris.add,
    ),
  );

  onLinkTap(const PdfLink(_linkRects));

  expect(tappedUris, isEmpty);
  expect(controller.dests, isEmpty);
}

Future<void> _twakePdfPreviewerForwardsOnLinkTap(WidgetTester tester) async {
  void onLinkTap(Uri uri) {}

  await tester.pumpWidget(
    MaterialApp(
      home: TwakePdfPreviewer(
        // Not `success`, so the native pdfrx viewer is not mounted.
        previewerOptions: const PreviewerOptions(
          previewerState: PreviewerState.loading,
        ),
        onLinkTap: onLinkTap,
      ),
    ),
  );

  final template = tester.widget<PreviewerTemplateWidget>(
    find.byType(PreviewerTemplateWidget),
  );
  expect((template.child as PdfPreviewer).onLinkTap, same(onLinkTap));
}

void main() {
  testWidgets(
    'TwakePdfPreviewer forwards onLinkTap to PdfPreviewer',
    _twakePdfPreviewerForwardsOnLinkTap,
  );

  group('PdfPreviewer link tap', () {
    testWidgets(
      'forwards a URL link to onLinkTap',
      _urlLinkIsForwardedToOnLinkTap,
    );
    testWidgets(
      'navigates to the destination of an internal link',
      _destLinkNavigatesInsideDocument,
    );
    testWidgets(
      'does not navigate when the link has both a URL and a destination',
      _linkWithUrlAndDestOnlyCallsOnLinkTap,
    );
    testWidgets(
      'does nothing for a URL link when onLinkTap is not set',
      _urlLinkWithoutOnLinkTapDoesNothing,
    );
    testWidgets(
      'does nothing for a link without URL nor destination',
      _linkWithoutUrlNorDestDoesNothing,
    );
  });
}
