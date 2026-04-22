{{flutter_js}}
{{flutter_build_config}}

(function () {
  const mapsApiKey = window.GOOGLE_MAPS_API_KEY || "";

  function loadFlutterApp() {
    // flutter_build_config (injected above) already contains the service
    // worker version, so no extra arguments are needed here.
    _flutter.loader.load();
  }

  if (!mapsApiKey) {
    console.warn(
      "GOOGLE_MAPS_API_KEY is not configured for web; continuing without Google Maps JavaScript API.",
    );
    loadFlutterApp();
    return;
  }

  // Check if Maps JS API is already loading / loaded (e.g. injected by index.html).
  const existingScript = document.querySelector(
    'script[data-google-maps-sdk="true"]',
  );
  if (existingScript) {
    // Wait for it to finish loading before starting Flutter.
    if (window.google && window.google.maps) {
      loadFlutterApp();
    } else {
      existingScript.addEventListener("load", loadFlutterApp);
      existingScript.addEventListener("error", loadFlutterApp);
    }
    return;
  }

  // Inject Maps JS API using the classic (non-async) loader so that
  // window.google.maps.Map / Marker / etc. are fully available synchronously
  // by the time google_maps_flutter_web initialises.
  // NOTE: do NOT add "loading=async" here — that switches to the new
  // lazy-import API which is incompatible with google_maps_flutter_web.
  const script = document.createElement("script");
  script.src =
    "https://maps.googleapis.com/maps/api/js" +
    "?key=" + encodeURIComponent(mapsApiKey) +
    "&libraries=geometry,places&language=en";
  script.async = true;
  script.defer = true;
  script.dataset.googleMapsSdk = "true";
  script.onload = loadFlutterApp;
  script.onerror = function () {
    console.error("Failed to load Google Maps JavaScript API for web.");
    loadFlutterApp();
  };
  document.head.appendChild(script);
})();




