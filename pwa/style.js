const url = new URL(window.location),
      params = url.searchParams,
      dark_mode = params.get('dark_mode');

if (dark_mode == '1') {
  document.body.style.backgroundColor = '#121212';
  document.body.style.color = 'white';
}
