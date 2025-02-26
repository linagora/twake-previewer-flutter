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
      hyperLinks[i].addEventListener('click', onClickHyperLink);
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
        window.parent.addEventListener('message', handleMessage, false);
        window.addEventListener('load', handleOnLoad);
        window.addEventListener('pagehide', (event) => {
          window.parent.removeEventListener('message', handleMessage, false);
        });
      
        function handleMessage(e) {
          if (e && e.data && e.data.includes("toIframe:")) {
            var data = JSON.parse(e.data);
            if (data["view"].includes("$createdViewId")) {
              if (data["type"].includes("getHeight")) {
                var height = document.body.scrollHeight;
                window.parent.postMessage(JSON.stringify({"view": "$createdViewId", "type": "toDart: htmlHeight", "height": height}), "*");
              }
              if (data["type"].includes("getWidth")) {
                var width = document.body.scrollWidth;
                window.parent.postMessage(JSON.stringify({"view": "$createdViewId", "type": "toDart: htmlWidth", "width": width}), "*");
              }
              if (data["type"].includes("execCommand")) {
                if (data["argument"] === null) {
                  document.execCommand(data["command"], false);
                } else {
                  document.execCommand(data["command"], false, data["argument"]);
                }
              }
            }
          }
        }
        
        $handleOnClickEmailLinkMethod
        
        $handleOnClickHyperLinkMethod
        
        function handleOnLoad() {
          window.parent.postMessage(JSON.stringify({"view": "$createdViewId", "message": "$iframeOnLoadMessage"}), "*");
          window.parent.postMessage(JSON.stringify({"view": "$createdViewId", "type": "toIframe: getHeight"}), "*");
          window.parent.postMessage(JSON.stringify({"view": "$createdViewId", "type": "toIframe: getWidth"}), "*");
          
          $onLoadHyperLinkScript
          
          $onLoadMailtoScript
        }
      </script>''';
  }

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
