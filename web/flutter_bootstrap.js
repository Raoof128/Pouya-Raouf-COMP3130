{{flutter_js}}
{{flutter_build_config}}

(function () {
  const mapsApiKey = window.GOOGLE_MAPS_API_KEY || "";
  const serviceWorkerVersion = {{flutter_service_worker_version}};

  function loadFlutterApp() {
    _flutter.loader.load({
      serviceWorker: {
        serviceWorkerVersion: serviceWorkerVersion,
      },
    });
  }

  if (!mapsApiKey) {
    console.warn(
      "GOOGLE_MAPS_API_KEY is not configured for web; continuing without Google Maps JavaScript API.",
    );
    loadFlutterApp();
    return;
  }

  const existingScript = document.querySelector(
    'script[data-google-maps-sdk="true"]',
  );
  if (existingScript) {
    loadFlutterApp();
    return;
  }

  const script = document.createElement("script");
  script.src =
    "https://maps.googleapis.com/maps/api/js?loading=async&key=" +
    encodeURIComponent(mapsApiKey);
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
