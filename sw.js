var CACHE_NAME = 'taweqe-cache-v1';
var urlsToCache = [
  '/',
  '/index.html',
  '/recovery.html',
  '/Taweqa-ogretk/js/1-config.js',
  '/Taweqa-ogretk/js/2-utils.js',
  '/Taweqa-ogretk/js/3-auth.js',
  '/Taweqa-ogretk/js/4-landing.js',
  '/Taweqa-ogretk/js/5-driver-meter.js',
  '/Taweqa-ogretk/js/6-passenger.js',
  '/Taweqa-ogretk/js/7-chat.js',
  '/Taweqa-ogretk/js/8-wallet.js',
  '/Taweqa-ogretk/js/9-paymob.js',
  '/Taweqa-ogretk/js/9-init.js',
  '/Taweqa-ogretk/js/supabase-lite.js',
  '/Taweqa-ogretk/css/1-variables.css',
  '/Taweqa-ogretk/css/2-landing.css',
  '/Taweqa-ogretk/css/3-auth.css',
  '/Taweqa-ogretk/css/4-app.css',
  '/Taweqa-ogretk/favicon.png',
  '/Taweqa-ogretk/manifest.json'
];

self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      return cache.addAll(urlsToCache);
    })
  );
  self.skipWaiting();
});

self.addEventListener('activate', function(event) {
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames.map(function(name) {
          if (name !== CACHE_NAME) return caches.delete(name);
        })
      );
    })
  );
  self.clients.claim();
});

self.addEventListener('fetch', function(event) {
  event.respondWith(
    caches.match(event.request).then(function(response) {
      return response || fetch(event.request);
    })
  );
});
