def open_url(url)
  # open_url(): Open URL in Chrome
  system ({ 'LD_LIBRARY_PATH' => '' }), '/usr/bin/dbus-send',
      '--system',
      '--type=method_call',
      '--print-reply',
      '--dest=org.chromium.UrlHandlerService',
      '/org/chromium/UrlHandlerService',
      'org.chromium.UrlHandlerServiceInterface.OpenUrl',
      "string:#{url}"
end