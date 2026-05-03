{{flutter_js}}
{{flutter_build_config}}

const clearFlutterCaches = async () => {
  if ('serviceWorker' in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(registrations.map((registration) => registration.unregister()));
  }
  if ('caches' in window) {
    const keys = await caches.keys();
    await Promise.all(keys.map((key) => caches.delete(key)));
  }
};

clearFlutterCaches().finally(() => {
  _flutter.loader.load({
    config: {
      renderer: 'canvaskit',
    },
  });
});
