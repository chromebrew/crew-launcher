navigator.serviceWorker.register('./sw.js')
           
self.addEventListener('appinstalled', (event) => {
  // tell socket server to stop
  fetch('/stop', { method: 'POST' }).then( () => {
    // show close message
    document.getElementById('installBut').style.visibility = 'hidden';
    document.getElementById('closeMsg').style.visibility = 'visible';
  });
});

self.addEventListener('beforeinstallprompt', (e) => {
  self.InstallPrompt = e
});

installBut.addEventListener('click', () => {
  self.InstallPrompt.prompt();
});
