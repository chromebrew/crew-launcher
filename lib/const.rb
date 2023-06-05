LOG_FILE = '/tmp/crew-launcher.log'
PID_FILE = '/tmp/crew-launcher.pid'

HELP = <<EOF
crew-launcher: Add Chromebrew applications to launcher

Usage:
  add|new <*.desktop file>           add an application to launcher
  start|start-server                 start launcher server for shortcut
  stat|status                        display launcher server status
  stop|stop-server                   stop launcher server if running
  open-ui                            open application picker UI
  help                               show this message
EOF

SERVER_PORT = 25500
WEBSTATIC_DIR = File.expand_path('../webstatic', __dir__)

# search path of desktop entry files and icons
ICON_SEARCH_PATH = %w[/usr/local/share/icons /usr/local/share/pixmaps]
APP_SEARCH_PATH = %w[/usr/local/share/applications]