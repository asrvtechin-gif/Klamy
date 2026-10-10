importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyC6fj1bLNbVZjTSi1lV5SvIkKLf0rGQY4Q',
  authDomain: 'klamy-8789e.firebaseapp.com',
  databaseURL: 'https://klamy-8789e-default-rtdb.firebaseio.com',
  projectId: 'klamy-8789e',
  storageBucket: 'klamy-8789e.firebasestorage.app',
  messagingSenderId: '1060317334078',
  appId: '1:1060317334078:web:c168908b20cf8b693a5f6f',
  measurementId: 'G-SDMMFY4B2N',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || payload.data?.title || 'Klamy update';
  const options = {
    body: payload.notification?.body || payload.data?.body || '',
    icon: '/icons/Icon-192.png',
    data: payload.data || {},
  };
  return self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = self.location.origin + '/';
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clients) => {
      for (const client of clients) {
        if ('focus' in client) return client.focus();
      }
      return self.clients.openWindow(targetUrl);
    }),
  );
});
