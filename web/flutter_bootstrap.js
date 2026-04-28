{{flutter_js}}
{{flutter_build_config}}

(function () {
  'use strict';

  if ('serviceWorker' in navigator) {
    navigator.serviceWorker
      .register('sw.js', { scope: './' })
      .then(function (registration) {
        registration.update();
      })
      .catch(function (err) {
        console.warn('[PeacePal] Service worker registration failed:', err);
      });
  }

  // Use HTML renderer so emoji characters render via the browser's built-in
  // system fonts (Apple Color Emoji, Noto Color Emoji, Segoe UI Emoji, etc.)
  // instead of requiring an online CDN emoji font download (CanvasKit default).
  // This makes emoji work offline without needing to cache any remote font.
  _flutter.loader.load({
    renderer: 'html',
    onEntrypointLoaded: function (engineInitializer) {
      engineInitializer.initializeEngine().then(function (appRunner) {
        appRunner.runApp();
      });
    },
  });
})();
