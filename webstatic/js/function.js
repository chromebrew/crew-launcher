// function.js: shared functions
function showPopup(text) {
  // showPopup(): show a popup on the bottom of page
  let resolvePromise;

  const promise = new Promise((resolve, _) => resolvePromise = resolve),
        popup   = document.createElement('div'),
        infoIco = new Image();

  popup.className = 'popup close';
  infoIco.src     = '/static/img/info.svg';

  popup.appendChild(infoIco);
  popup.innerHTML += `<p>${text}</p>`;

  document.body.appendChild(popup);

  // animation stuff
  setTimeout(() => {
    popup.classList.remove('close');

    popup.ontransitionend = () => {
      setTimeout(() => {
        popup.classList.add('close');
        popup.ontransitionend = () => {
          document.body.removeChild(popup)
          resolvePromise();
        };
      }, 5000);
    };
  }, 100);

  return promise;
}

function getImageSize(img) {
  // getImageSize(): get the size of given image
  const imgElement = new Image();
  const promise    = new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject('Takes too long'), 10000);

    imgElement.onload = () => {
      clearTimeout(timeout);
      resolve([imgElement.naturalWidth, imgElement.naturalHeight]);
    };
  });

  imgElement.src = img;
  return promise;
}

function resizeIcon(img, width = 144, height = 144) {
  // resizeIcon(): Resize icon to meet the minimal criteria of PWA
  const imgElement = new Image(),
        canvas     = document.createElement('canvas'),
        ctx        = canvas.getContext('2d');

  canvas.height = height;
  canvas.width  = width;

  imgElement.src = img;
  ctx.drawImage(imgElement, 0, 0, width, height);

  return canvas.toDataURL('image/png');
}

function getCSSVar(varName) {
  return getComputedStyle(document.documentElement).getPropertyValue(varName);
}

async function getIconInfo(entry) {
  // getIconInfo(): Generate icon list for PWA manifest based on the icon listed in the desktop entry object
  const mainGroup = entry['Desktop Entry'];

  if (mainGroup.Icon.available.length === 0) {
    return [{ type: 'image/png', sizes: '512x512', src: `${location.origin}/static/img/brew.png` }];
  } else {
    return await Promise.all(mainGroup.Icon.available.map(async ico => {
      const iconURL = `${location.origin}/fs` + ico;

      // set the size to 'any' if the icon is SVG
      // otherwise extract the size from path
      if (ico.endsWith('.svg')) {
        return { type: 'image/svg+xml', sizes: 'any', src: iconURL };
      } else {
        // get size using DOM if the path does not include the size
        const imgSize = ico.match(/\d+x\d+/)?.[0] || (await getImageSize(iconURL)).join('x');
        return { type: 'image/png', sizes: imgSize, src: iconURL };
      }
    })).then(icons => icons.sort((a, b) => {
      const aSize = parseInt(a.sizes.replace('any', '9999x9999').match(/^\d+/)[0]),
            bSize = parseInt(b.sizes.replace('any', '9999x9999').match(/^\d+/)[0]);

      if (aSize === bSize) {
        return 0;
      } else if (aSize > bSize) {
        return -1;
      } else {
        return 1;
      }
    }));
  }
}

function generatePWAManifest(entryPath, entry, icons) {
  const mainGroup = entry['Desktop Entry'],
        start_url = location.origin + '/api/desktopEntry' + entryPath +
                    `?action=startApp&primaryIcon=${encodeURIComponent(icons[0].src)}`;

  return {
    background_color: getCSSVar('--bg-color'),
    theme_color: getCSSVar('--bg-color'),
    display: 'standalone',

    id: `/?entryId=${entryPath.match(/([^\/]+)\.desktop$/)[1]}`,
    scope: location.origin + '/api/desktopEntry' + entryPath,
    start_url: start_url,

    name: mainGroup['Name'],
    short_name: mainGroup['GenericName'],
    description: mainGroup['Comment'],
    icons: icons,

    shortcuts: (mainGroup['Actions'] || '').split(';').filter(i => i).map(action => {
      const actionGroup = entry[`Desktop Action ${action}`];
      return {
        name: actionGroup['Name'],
        url: start_url + `&shortcut=${encodeURIComponent(action)}`
      }
    })
  };
}