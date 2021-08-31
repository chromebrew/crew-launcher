navigator.serviceWorker.register('./sw.js')
           
self.addEventListener('appinstalled', (event) => {
  // tell socket server to stop
  fetch('/stop', { method: 'POST' }).then( () => {
    alert('You can close this window now.');
  });
});

self.addEventListener('beforeinstallprompt', (e) => {
  self.InstallPrompt = e
});

installBut.addEventListener('click', () => {
  self.InstallPrompt.prompt();
});
