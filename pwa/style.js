const url = new URL(window.location),
      params = url.searchParams,
      dark_mode = params.get('dark_mode');

if (dark_mode == '1') {
  document.getElementsByTagName('body').style.backgroundColor = '#121212';
}
