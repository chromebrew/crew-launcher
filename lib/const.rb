Args = ARGV.grep(/^--/).map do |arg|
  [ arg.sub('--', ''), true ]
end.to_h

PORT = 25500
CREW_PREFIX = (ENV['CREW_PREFIX'].to_s.empty?) ? '/usr/local' : ENV['CREW_PREFIX']
SHAREDIR = "#{CREW_PREFIX}/share"
APPDIR = "#{SHAREDIR}/crew-launcher"
TMPDIR = "/tmp/crew-launcher"
ICONDIR = "#{APPDIR}/icon"
CONFIGDIR = "#{APPDIR}/json"
CREWICON = "#{ICONDIR}/brew.png"

IconSearchGlob = [
  "#{SHAREDIR}/icons/*/*/*/%s",
  "#{SHAREDIR}/pixmaps/%s",
  "#{ICONDIR}/%s"
]

HELP = <<EOF
crew-launcher: Add Chromebrew applications to launcher

Usage:
  add <pkgname|*.desktop file>     add an application to launcher
  list                             display all installed launcher apps
  remove <pkgname|*.desktop file>  remove existing profile(s) for application(s)
  start|start-server               start launcher server for shortcut
  stat|status                      display launcher server status
  stop|stop-server                 stop launcher server if running
  help                             show this message
  uuid <pkgname|*.desktop file>    returns the UUID of specific profile(s)
EOF

# get locale settings from LC_MESSAGES env variable
unless ENV['LC_MESSAGES'].to_s.empty?
  LC_MESSAGES = ENV['LC_MESSAGES'].scan(/([\._@]?)([^\._@]+)/).to_h
  Locale = { lang: LC_MESSAGES[''], country: LC_MESSAGES['_'], modifier: LC_MESSAGES['@'] }
else
  Locale = nil
end
