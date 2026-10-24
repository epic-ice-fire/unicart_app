// Kill switch: removes any earlier UniCart service worker. No caching, no reloads.
self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", (event) => {
  event.waitUntil(
    self.registration.unregister().then(() =>
      caches.keys().then((keys) => Promise.all(keys.map((k) => caches.delete(k))))
    )
  );
});
