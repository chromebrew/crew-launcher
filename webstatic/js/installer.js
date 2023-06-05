const manifestLink   = document.getElementById('manifestLink'),
      appIconInput   = document.createElement('input'),
      appIconElement = document.getElementById('appIcon'),
      appNameElement = document.getElementById('appName'),
      installBtn     = document.getElementById('installBtn');

appIconInput.type   = 'file';
appIconInput.accept = 'image/*';

self.addEventListener('appinstalled', async () => {
  if (window.opener) {
    window.opener.showPopup(`Added ${manifest.name} to the launcher`);
    window.close();
  } else {
    installBtn.disabled = true;
    await showPopup(`Added ${manifest.name} to the launcher`);
    window.close();
  }
});

self.addEventListener('beforeinstallprompt', e => window.resolveInstallPromptPromise(e));

// file picker for customize icon
appIconInput.onchange = async e => {
  // manifest does not support object URL, use data URL instead
  // convert uploaded icon to data URL
  const newIcon = e.target.files[0],
        reader  = new FileReader();

  reader.readAsDataURL(newIcon);

  let newIconURL  = await new Promise((resolve, _) => { reader.onload = e => resolve(e.target.result); }),
      newIconSize = await getImageSize(newIconURL);

  if (Math.max(...newIconSize) > 512 || Math.min(...newIconSize) < 144) {
    newIconURL  = resizeIcon(newIconURL, 512, 512);
    newIconSize = [512, 512];
  }

  console.log('New icon:', newIconURL);

  appIconElement.src = newIconURL;
  manifest.icons     = [{ src: newIconURL, sizes: newIconSize.join('x'), type: newIcon.type }];
};

appIconElement.onclick = () => appIconInput.click();

installBtn.onclick = async () => {
  if (!(manifest.icons[0].sizes === 'any' || parseInt(manifest.icons[0].sizes.match(/^\d+/)?.[0]) >= 144)) {
    const iconSrc     = manifest.icons[0].src,
          resizedIcon = resizeIcon(iconSrc);

    manifest.icons.push({ src: resizedIcon, sizes: '144x144', type: 'image/png' });
  }

  const promptPromise = new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject('prompt popup takes too long'), 1000);
    window.resolveInstallPromptPromise = e => {
      clearTimeout(timeout);
      resolve(e);
    }
  });

  manifest.name = appNameElement.value; // use customized name specified by user (if exist)
  // apply manifest to page
  manifestLink.href = URL.createObjectURL(new Blob([JSON.stringify(manifest)], { type: 'application/manifest+json' }));

  try {
    (await promptPromise).prompt();
  } catch(err) {
    console.error(err);
    console.warn('Failed to trigger the PWA installation prompt. (does this application already added to launcher?)');
    showPopup('Failed to show the PWA installation prompt. (Does it already added to the launcher?)');
  }
}

(async () => {
  // use generated manifest from add2launcher.js if this page is opened by add2launcher.js
  if (window.opener) {
    window.manifest = window.opener.manifest
  } else {
    const entry = await fetch(location.pathname + '?action=getParsed').then(r => r.json()),
          icons = await getIconInfo(entry);

    window.manifest = generatePWAManifest(location.pathname.replace('/api/desktopEntry', ''), entry, icons);
  }

  appIconElement.src   = manifest.icons[0].src;
  appNameElement.value = manifest.name;

  navigator.serviceWorker.register('/sw.js');
})();