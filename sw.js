const CACHE_NAME = 'peacepal-sw-v3';

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(installCache());
});

async function installCache() {
  const cache = await caches.open(CACHE_NAME);

  // Cache the app shell
  await cache.add(new Request('./', { cache: 'reload' }));

  // Pre-cache fonts so icon/emoji text renders correctly offline.
  // Fonts are loaded very early in Flutter init — before the SW has claimed
  // the page via clients.claim() — so runtime caching alone misses them.
  // Path is 'assets/' (build output), NOT 'flutter_assets/' (Dart source alias).
  try {
    const fontManifest = await fetch('assets/FontManifest.json').then((r) => r.json());
    const fontUrls = (fontManifest ?? []).flatMap((family) =>
      (family.fonts ?? []).map((f) => f.asset).filter(Boolean).map((a) => 'assets/' + a)
    );
    await Promise.allSettled(
      fontUrls.map((url) =>
        fetch(url).then((res) => {
          if (res && res.ok) cache.put(url, res);
        })
      )
    );
  } catch (_) {
    // Pre-caching is best-effort; install must not fail
  }
}

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  if (!url.protocol.startsWith('http')) return;

  // Cache cross-origin emoji / icon fonts loaded by CanvasKit renderer
  // (gstatic.com supports CORS so responses are cacheable, not opaque)
  if (url.hostname.endsWith('gstatic.com') || url.hostname.endsWith('googleapis.com')) {
    event.respondWith(cacheFirstAsset(request));
    return;
  }

  if (url.origin !== self.location.origin) return;

  if (request.mode === 'navigate') {
    event.respondWith(networkFirstNavigation(request));
    return;
  }

  event.respondWith(cacheFirstAsset(request));
});

async function networkFirstNavigation(request) {
  const cache = await caches.open(CACHE_NAME);
  try {
    const networkResponse = await fetch(request);
    if (networkResponse && networkResponse.status === 200) {
      cache.put(request, networkResponse.clone());
      cache.put('./', networkResponse.clone());
    }
    return networkResponse;
  } catch (_) {
    const cached = (await cache.match(request)) || (await cache.match('./'));
    if (cached) return cached;
    return new Response(
      '<!DOCTYPE html><html><head><meta charset="utf-8">' +
        '<meta name="viewport" content="width=device-width,initial-scale=1">' +
        '<title>PeacePal</title>' +
        '<style>body{font-family:sans-serif;display:flex;align-items:center;' +
        'justify-content:center;min-height:100vh;margin:0;background:#F8FAFD}' +
        '.box{text-align:center;padding:2rem}h1{color:#2563EB}p{color:#555}</style>' +
        '</head><body><div class="box">' +
        '<h1>PeacePal</h1><p>Bạn đang offline.<br>Vui lòng kết nối mạng và thử lại.</p>' +
        '</div></body></html>',
      { status: 503, headers: { 'Content-Type': 'text/html; charset=utf-8' } }
    );
  }
}

async function cacheFirstAsset(request) {
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(request);

  // Always revalidate in background so next load gets fresh asset
  const fetchPromise = fetch(request).then((networkResponse) => {
    if (networkResponse && networkResponse.status === 200) {
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  }).catch(() => null);

  return cached ?? (await fetchPromise) ?? new Response('', { status: 503, statusText: 'Offline' });
}
