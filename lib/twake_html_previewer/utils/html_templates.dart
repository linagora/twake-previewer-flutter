import 'package:flutter/widgets.dart';

typedef CreatedViewId = String;

class HtmlTemplates {
  const HtmlTemplates._();

  static String _getOnClickEmailLinkMethod(CreatedViewId createdViewId) => '''
    function handleOnClickEmailLink(e) {
      var href = this.href;
      window.parent.postMessage(JSON.stringify({"view": "$createdViewId", "type": "toDart: OpenLink", "url": "" + href}), "*");
      e.preventDefault();
    }''';
  static String get _onLoadMailtoScript => '''
    var emailLinks = document.querySelectorAll('a[href^="mailto:"]');
    for (var i=0; i < emailLinks.length; i++){
      emailLinks[i].addEventListener('click', handleOnClickEmailLink);
    }''';

  static String _getOnClickHyperLinkMethod(
    CreatedViewId createdViewId, {
    required String onClickHyperLinkName,
  }) =>
      '''
    function handleOnClickHyperLink(e) {
      var href = this.href;
      window.parent.postMessage(JSON.stringify({"view": "$createdViewId", "type": "toDart: $onClickHyperLinkName", "url": "" + href}), "*");
      e.preventDefault();
    }''';
  static String get _onLoadHyperLinkScript => '''
    var hyperLinks = document.querySelectorAll('a');
    for (var i=0; i < hyperLinks.length; i++){
      hyperLinks[i].addEventListener('click', handleOnClickHyperLink);
    }''';

  static String getWebViewActionScript(
    CreatedViewId createdViewId, {
    required String iframeOnLoadMessage,
    bool mailtoDelegateAvailable = false,
    bool hyperLinkClickHandlerAvailable = false,
    String onClickHyperLinkName = '',
  }) {
    String handleOnClickEmailLinkMethod = '';
    String onLoadMailtoScript = '';
    if (mailtoDelegateAvailable) {
      handleOnClickEmailLinkMethod = HtmlTemplates._getOnClickEmailLinkMethod(
        createdViewId,
      );
      onLoadMailtoScript = HtmlTemplates._onLoadMailtoScript;
    }

    String handleOnClickHyperLinkMethod = '';
    String onLoadHyperLinkScript = '';
    if (hyperLinkClickHandlerAvailable) {
      handleOnClickHyperLinkMethod = HtmlTemplates._getOnClickHyperLinkMethod(
        createdViewId,
        onClickHyperLinkName: onClickHyperLinkName,
      );
      onLoadHyperLinkScript = HtmlTemplates._onLoadHyperLinkScript;
    }

    return '''
      <script type="text/javascript">
        window.addEventListener('message', handleMessage, false);
        window.addEventListener('load', handleOnLoad);
        window.addEventListener('pagehide', (event) => {
          window.removeEventListener('message', handleMessage, false);
        });
      
        ${_getHandleMessageMethod()}
        
        $handleOnClickEmailLinkMethod
        
        $handleOnClickHyperLinkMethod
        
        ${_getHandleOnLoadMethod(
      createdViewId,
      iframeOnLoadMessage: iframeOnLoadMessage,
      onLoadHyperLinkScript: onLoadHyperLinkScript,
      onLoadMailtoScript: onLoadMailtoScript,
    )}
      </script>''';
  }

  static String _getHandleMessageMethod() =>
      '''
        function handleMessage(e) {
          if (!e || e.source !== window.parent) return;
          if (e.data === '{"type":"toIframe: clearSelection"}') {
            var selection = window.getSelection();
            if (selection) selection.removeAllRanges();
          }
        }
      ''';

  static String _getHandleOnLoadMethod(
    CreatedViewId createdViewId, {
    required String iframeOnLoadMessage,
    required String onLoadHyperLinkScript,
    required String onLoadMailtoScript,
  }) =>
      '''
        function handleOnLoad() {
          window.parent.postMessage(JSON.stringify({"view": "$createdViewId", "message": "$iframeOnLoadMessage"}), "*");
          // Measure after the other load handlers have run.
          setTimeout(function() {
            window.parent.postMessage(JSON.stringify({"view": "$createdViewId", "type": "toDart: htmlHeight", "height": document.body.scrollHeight}), "*");
            window.parent.postMessage(JSON.stringify({"view": "$createdViewId", "type": "toDart: htmlWidth", "width": document.body.scrollWidth}), "*");
          }, 0);
          
          $onLoadHyperLinkScript
          
          $onLoadMailtoScript
        }
      ''';

  static String getDisableZoomScript() => '''
    <script type="text/javascript">
      document.addEventListener('wheel', function(e) {
        e.ctrlKey && e.preventDefault();
      }, {passive: false});
      window.addEventListener('keydown', function(e) {
        if (event.metaKey || event.ctrlKey) {
          switch (event.key) {
            case '=':
            case '-':
              event.preventDefault();
              break;
          }
        }
      });
    </script>''';

  static String generate({
    required String content,
    required String contentClassName,
    double? minHeight,
    double? minWidth,
    String? styleCSS,
    String? javaScripts,
    bool hideScrollBar = true,
    TextDirection? direction,
  }) {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
      <style>
        .$contentClassName {
          min-height: ${minHeight ?? 0}px;
          min-width: ${minWidth ?? 0}px;
          overflow: auto;
        }
        ${hideScrollBar ? '''
          .tmail-content::-webkit-scrollbar {
            display: none;
          }
          .tmail-content {
            -ms-overflow-style: none;  /* IE and Edge */
            scrollbar-width: none;  /* Firefox */
          }
        ''' : ''}
        ${styleCSS ?? ''}
      </style>
      </head>
      <body ${direction == TextDirection.rtl ? 'dir="rtl"' : ''} style = "overflow-x: hidden">
      <div class="$contentClassName">$content</div>
      ${javaScripts ?? ''}
      </body>
      </html> 
    ''';
  }
}
