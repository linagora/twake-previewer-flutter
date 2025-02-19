final platformViewRegistry = PlatformViewRegistry();

class PlatformViewRegistry {
  /// Shim for registerViewFactory
  /// https://github.com/flutter/engine/blob/master/lib/web_ui/lib/ui.dart#L72
  void registerViewFactory(
      String viewTypeId, dynamic Function(int viewId) viewFactory) {}
}
