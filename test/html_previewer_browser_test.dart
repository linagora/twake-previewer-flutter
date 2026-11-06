@TestOn('chrome')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
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
      'selection:0:{"type":"toIframe: clearSelection"}',
    );
  });

  testWidgets(
    'SHOULD keep its selection when a sibling frame posts clearSelection',
    (tester) async {
      final selected = _nextProbe((m) => m.startsWith('selected:'));
      final iframe = await _pumpPreview(tester, _selectionProbe);

      expect(
        await tester.runAsync(() => selected.timeout(_wait)),
        isNot('selected:0'),
      );

      iframe.id = 'preview-frame';
      final after = _nextProbe((m) => m.contains('toIframe: clearSelection'));
      final attacker = html.IFrameElement()
        ..setAttribute('sandbox', 'allow-scripts allow-same-origin')
        ..srcdoc = '<script>'
            'parent.document.getElementById("preview-frame").contentWindow'
            '.postMessage(\'{"type":"toIframe: clearSelection"}\', "*");'
            '</script>';
      html.document.body!.append(attacker);
      addTearDown(attacker.remove);

      expect(
        await tester.runAsync(() => after.timeout(_wait)),
        isNot(startsWith('selection:0')),
      );
    },
  );

  testWidgets('SHOULD grow past heightContent after the frame reports its size', (
    tester,
  ) async {
    const heightContent = 300.0;
    final loaded = Completer<void>.sync();
    _connectFrameBeforeSrcdoc();

    await _pumpPreview(
      tester,
      '<div style="height:800px"></div>',
      heightContent: heightContent,
      onLoaded: loaded.complete,
    );

    await tester.runAsync(() => loaded.future.timeout(_wait));
    await tester.pump();

    expect(
      tester
          .widget<SizedBox>(
            find.descendant(
              of: find.byType(HtmlPreviewer),
              matching: find.byType(SizedBox),
            ),
          )
          .height,
      greaterThan(heightContent),
    );
  });

  group('message source', () {
    testWidgets('SHOULD forward a link click posted by its own iframe', (
      tester,
    ) async {
      // Sync, because a fake-async microtask would wait for a pump during runAsync.
      final click = Completer<Uri?>.sync();

      await _pumpPreview(tester, _ownLinkClick, onClick: click.complete);

      expect(
        await tester.runAsync(() => click.future.timeout(_wait)),
        Uri.parse(_ownUrl),
      );
    });

    testWidgets(
      'SHOULD NOT forward a link click forged by the host window with its view id',
      (tester) async {
        final clicks = <Uri?>[];
        final iframe = await _pumpPreview(tester, _plainLink, onClick: clicks.add);

        for (final message in _forgedMessages(_viewIdOf(iframe))) {
          html.window.postMessage(jsonEncode(message), '*');
        }
        await tester.runAsync(() => Future<void>.delayed(_settle));

        expect(clicks, isEmpty);
      },
    );

    testWidgets(
      'SHOULD NOT forward a link click posted by a nested frame with its view id',
      (tester) async {
        final clicks = <Uri?>[];
        final delivered = tester.runAsync(
          () => _nextProbe((m) => m == 'nested').timeout(_wait),
        );
        await _pumpPreview(tester, _nestedForgery, onClick: clicks.add);
        await delivered;
        expect(clicks, isEmpty);
      },
    );

    testWidgets(
      'SHOULD NOT forward a link click posted by another iframe with its view id',
      (tester) async {
        final clicks = <Uri?>[];
        final iframe = await _pumpPreview(tester, _plainLink, onClick: clicks.add);

        final attacker = html.IFrameElement()
          ..setAttribute('sandbox', 'allow-scripts')
          ..srcdoc = '<script>for (const m of '
              '${jsonEncode(_forgedMessages(_viewIdOf(iframe)))}) '
              'window.parent.postMessage(JSON.stringify(m), "*");</script>';
        html.document.body!.append(attacker);
        addTearDown(attacker.remove);
        await tester.runAsync(() => Future<void>.delayed(_settle));

        expect(clicks, isEmpty);
      },
    );
  });
}

const _wait = Duration(seconds: 5);
const _settle = Duration(milliseconds: 500);
const _ownUrl = 'https://own.example/a';
const _otherUrl = 'https://other.example/b';
const _plainLink = '<a href="$_ownUrl">link</a>';

const _ownLinkClick = '''
<a id="l" href="$_ownUrl">link</a>
<script>
  window.addEventListener('load', () => setTimeout(
    () => document.getElementById('l').click(), 0));
</script>''';

String _viewIdOf(html.IFrameElement iframe) =>
    RegExp(r'"view": "([^"]+)"').firstMatch(iframe.srcdoc!)!.group(1)!;

/// The load handshake and a link click, as the frame's own bridge posts them.
List<Map<String, String>> _forgedMessages(String viewId) => [
      {'view': viewId, 'message': 'iframeHasBeenLoaded'},
      {'view': viewId, 'type': 'toDart: onClickHyperLink', 'url': _otherUrl},
    ];

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
  window.addEventListener('message', (e) => setTimeout(
    () => report('selection:' + window.getSelection().rangeCount + ':' + e.data), 0));
</script>''';

const _nestedForgery = '''
<script>
  window.addEventListener('load', () => {
    const view = document.documentElement.innerHTML
        .match(/"view": "([A-Za-z0-9_-]{10})"/)[1];
    const child = document.createElement('iframe');
    child.setAttribute('sandbox', 'allow-scripts');
    child.srcdoc = '<script>'
      + 'parent.parent.postMessage(JSON.stringify({view:"' + view
      + '",message:"iframeHasBeenLoaded"}),"*");'
      + 'parent.parent.postMessage(JSON.stringify({view:"' + view
      + '",type:"toDart: onClickHyperLink",url:"https://other.example/b"}),"*");'
      + 'parent.parent.postMessage(JSON.stringify({probe:"nested"}),"*");'
      + '</scr' + 'ipt>';
    document.body.appendChild(child);
  });
</script>
''';

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
  void Function()? onLoaded,
  double heightContent = 300,
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
          heightContent: heightContent,
          minHeight: 50,
          onClickHyperLinkAction: onClick,
          onLoaded: onLoaded,
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
  } else {
    // The srcdoc setter already appended this frame.
    addTearDown(iframe.remove);
  }
  return iframe;
}

/// A detached frame reports scrollHeight 0. Connect it before srcdoc loads.
void _connectFrameBeforeSrcdoc() {
  final object = globalContext['Object'] as JSObject;
  final proto =
      (globalContext['HTMLIFrameElement'] as JSObject)['prototype'] as JSObject;
  final desc = object.callMethod<JSObject>(
    'getOwnPropertyDescriptor'.toJS,
    proto,
    'srcdoc'.toJS,
  );
  final originalSet = desc['set'] as JSFunction;

  void setter(JSObject element, JSString value) {
    if ((element['isConnected'] as JSBoolean?)?.toDart != true) {
      final body = (globalContext['document'] as JSObject)['body'] as JSObject?;
      if (body != null) {
        body.callMethod('appendChild'.toJS, element);
        element.callMethod('getBoundingClientRect'.toJS);
      }
    }
    originalSet.callAsFunction(element, value);
  }

  // Browser tests run on the Flutter SDK, which is past this API's 3.6 floor.
  // ignore: sdk_version_since
  desc['set'] = setter.toJSCaptureThis;
  object.callMethod('defineProperty'.toJS, proto, 'srcdoc'.toJS, desc);
  addTearDown(() {
    desc['set'] = originalSet;
    object.callMethod('defineProperty'.toJS, proto, 'srcdoc'.toJS, desc);
  });
}

/// Probes post `{"probe": ...}` JSON, because the previewer json-decodes
/// every message of its own frame.
Future<String> _nextProbe(bool Function(String) test) => html.window.onMessage
    .map((e) => e.data)
    .where((d) => d is String && d.contains('"probe"'))
    .map((d) => (jsonDecode(d as String) as Map)['probe'] as String)
    .firstWhere(test);
