import 'package:flutter_test/flutter_test.dart';
import 'package:twake_previewer_flutter/twake_html_previewer/utils/html_templates.dart';

void main() {
  group('HtmlTemplates.getWebViewActionScript', () {
    final script = HtmlTemplates.getWebViewActionScript(
      'view1',
      iframeOnLoadMessage: 'loaded',
    );

    test('SHOULD listen on its own window, not the parent', () {
      expect(script, contains("window.addEventListener('message'"));
      expect(script, isNot(contains('window.parent.addEventListener')));
      expect(script, isNot(contains('window.parent.removeEventListener')));
    });

    test('SHOULD only accept messages posted by the parent window', () {
      expect(script, contains('e.source !== window.parent'));
    });

    test('SHOULD report its size itself instead of asking the parent', () {
      expect(script, contains('toDart: htmlHeight'));
      expect(script, contains('toDart: htmlWidth'));
      expect(script, isNot(contains('toIframe: getHeight')));
    });
  });
}
