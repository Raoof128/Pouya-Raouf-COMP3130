import 'dart:js_interop';

/// Reads `window.GOOGLE_MAPS_API_KEY` injected by `google_maps_config.js`.
@JS('GOOGLE_MAPS_API_KEY')
external JSString? get _jsGoogleMapsApiKey;

/// Returns true when the Maps JS API key is present in the web page.
bool hasWebGoogleMapsApiKey() {
  try {
    final key = _jsGoogleMapsApiKey;
    return key != null && key.toDart.trim().isNotEmpty;
  } catch (_) {
    return false;
  }
}
