@TestOn('chrome')
library;

import 'dart:convert';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_previewer_flutter/twake_html_previewer/widgets/html_previewer.dart';
import 'package:universal_html/html.dart' as html;

/// Widget tests ignore platform messages, so these tests let them through.
/// MaterialApp is omitted: its system-chrome call leaves a pending timer.
void main() {
  setUp(() {
    ui_web.TestEnvironment.setUp(
      const ui_web.TestEnvironment(
        forceTestFonts: true,
        disableFontFallbacks: true,
        keepSemanticsDisabledOnUpdate: true,
        defaultToTestUrlStrategy: true,
      ),
    );
    addTearDown(
      () => ui_web.TestEnvironment.setUp(
        const ui_web.TestEnvironment.flutterTester(),
      ),
    );
  });

  testWidgets(
    'SHOULD render the preview in a frame that cannot reach the host window',
    (tester) async {
      final verdict = _nextProbe((m) => m == 'blocked' || m == 'leak');

      await _pumpPreview(tester, _hostAccessProbe);

      expect(
        await tester.runAsync(
          () => verdict.timeout(const Duration(seconds: 5)),
        ),
        'blocked',
      );
    },
  );

  testWidgets('SHOULD clear its selection when the host posts clearSelection', (
    tester,
  ) async {
    final selected = _nextProbe((m) => m.startsWith('selected:'));

    final iframe = await _pumpPreview(tester, _selectionProbe);

    expect(
      await tester.runAsync(() => selected.timeout(const Duration(seconds: 5))),
      isNot('selected:0'),
    );

    final after = _nextProbe((m) => m.startsWith('selection:'));
    iframe.contentWindow!.postMessage('{"type":"toIframe: clearSelection"}', '*');

    expect(
      await tester.runAsync(() => after.timeout(const Duration(seconds: 5))),
      'selection:0',
    );
  });
}

const _selectionProbe = '''
<p>text</p>
<script>
  function report(p) {
    window.parent.postMessage(JSON.stringify({probe: p}), '*');
  }
  window.addEventListener('load', () => {
    window.getSelection().selectAllChildren(document.body);
    report('selected:' + window.getSelection().rangeCount);
  });
  window.addEventListener('message', () => setTimeout(
    () => report('selection:' + window.getSelection().rangeCount), 0));
</script>''';

const _hostAccessProbe = '''
<script>
  try {
    window.parent.document.title;
    window.parent.postMessage(JSON.stringify({probe: 'leak'}), '*');
  } catch (e) {
    window.parent.postMessage(JSON.stringify({probe: 'blocked'}), '*');
  }
</script>''';

Future<html.IFrameElement> _pumpPreview(
  WidgetTester tester,
  String content, {
  void Function(Uri?)? onClick,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 400,
        height: 400,
        child: HtmlPreviewer(
          contentHtml: content,
          contentClassName: 'preview',
          widthContent: 390,
          heightContent: 300,
          minHeight: 50,
          onClickHyperLinkAction: onClick,
        ),
      ),
    ),
  );
  await tester.pump();
  final id = tester
      .widget<PlatformViewSurface>(find.byType(PlatformViewSurface))
      .controller
      .viewId;
  final iframe =
      ui_web.platformViewRegistry.getViewById(id) as html.IFrameElement;
  // The test embedder leaves the platform view out of the document.
  if (iframe.isConnected != true) {
    html.document.body!.append(iframe);
    addTearDown(iframe.remove);
  }
  return iframe;
}

/// Probes post `{"probe": ...}` JSON, because the previewer json-decodes
/// every message of its own frame.
Future<String> _nextProbe(bool Function(String) test) => html.window.onMessage
    .map((e) => e.data)
    .where((d) => d is String && d.contains('"probe"'))
    .map((d) => (jsonDecode(d as String) as Map)['probe'] as String)
    .firstWhere(test);
