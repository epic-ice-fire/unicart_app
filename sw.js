// Minimal pass-through service worker. It makes UniCart installable as an app
// on phones without caching anything, so users never get a stale version.
self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", (event) => event.waitUntil(self.clients.claim()));
self.addEventListener("fetch", () => {});
