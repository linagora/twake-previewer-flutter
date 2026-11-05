import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// dart:html wraps foreign-frame windows in fresh objects, so compare the native ones.
bool isMessageFromIframe(Object event, Object? iframe) {
  if (iframe == null) return false;
  final source = (event as JSObject)['source'];
  final frameWindow = (iframe as JSObject)['contentWindow'];
  return source != null &&
      frameWindow != null &&
      source.strictEquals(frameWindow).toDart;
}
