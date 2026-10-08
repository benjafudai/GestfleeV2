self.addEventListener('install', function(event) {
  console.log('Service Worker installing.');
});

self.addEventListener('activate', function(event) {
  console.log('Service Worker activated.');
});

self.addEventListener('push', function(event) {
  let title = (event.data && event.data.text()) || "Nueva Notificación";
  let body = "Tienes una alerta de GestiónFlota";
  let icon = '/icon-192.png';
  let tag = 'push-simple-demo-notification-tag';

  event.waitUntil(
    self.registration.showNotification(title, {
      body: body,
      icon: icon,
      tag: tag
    })
  );
});
