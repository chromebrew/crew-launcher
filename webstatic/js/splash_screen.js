// get icon source from URL query
const uri_params = new URLSearchParams(location.search),
      appIcon    = document.getElementById('appIcon');

// primaryIcon: The URL of the icon, encoded with encodeURIComponent()
appIcon.src   = decodeURIComponent(uri_params.get('primaryIcon'));
window.onblur = () => setTimeout(window.close, 300);