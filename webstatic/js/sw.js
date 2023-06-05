// sw.js: Service Worker script

self.addEventListener('install', e => {
  // store offline page to cache
  e.waitUntil((async () => {
    const cache = await caches.open('v1'),
          filesToAdd = [
            '/static/offline.html'
          ];

    await cache.addAll(filesToAdd);
  })());
});

self.addEventListener('fetch', e => {
  // response with the offline page if cannot connect to crew-launcher
  e.respondWith((async () => {
    const controller = new AbortController(),
          cache      = (await caches.open('v1')).match('/static/offline.html');

    // maximum timeout for fetch()
    setTimeout(() => controller.abort(), 500);

    const response = await fetch(e.request, { signal: controller.signal }).catch(err => {
      console.error('An error occurs while sending request to the launcher daemon :/');
      return null;
    });

    return (response || cache);
  })());
});