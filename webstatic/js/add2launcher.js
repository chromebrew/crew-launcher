// list all available desktop entries
window.onload = async () => {
  const appListDiv = document.getElementById('appList'),
        json       = await fetch('/api/getAvailableEntries').then(response => response.json());

  json.forEach(async entry => {
    const mainGroup  = entry['Desktop Entry'],
          appDiv     = document.createElement('div'),
          availIcons = await getIconInfo(entry);

    appDiv.innerHTML = `<img src="${availIcons[0].src}" /><p>${mainGroup['Name']}</p>`;

    appDiv.onclick = async () => {
      window.showPopup = showPopup;
      window.manifest  = generatePWAManifest(entry['Path'], entry, availIcons);
      window.open('/api/desktopEntry' + entry['Path'] + '?action=installApp');
    };

    appListDiv.appendChild(appDiv);
  });
}