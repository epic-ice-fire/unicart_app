// Minimal service worker so UniCart is installable. It never touches API calls,
// scripts or assets: only page navigations are passed straight to the network,
// and nothing is cached, so users never get a stale version.
self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", (event) => event.waitUntil(self.clients.claim()));
self.addEventListener("fetch", (event) => {
  if (event.request.mode === "navigate") {
    event.respondWith(fetch(event.request));
  }
});
