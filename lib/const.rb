Args = ARGV.grep(/^--/).map do |arg|
  [ arg.sub('--', ''), true ]
end.to_h

Port = 25500
CREW_PREFIX = (ENV['CREW_PREFIX'].to_s.empty?) ? '/usr/local' : ENV['CREW_PREFIX']
LibPath = "#{CREW_PREFIX}/lib/crew-launcher/"
SharePath = "#{CREW_PREFIX}/share/"
TmpDir = "/tmp/crew-launcher/"
DataDir = "#{SharePath}/crew-launcher/"
PWAIconPath = "#{DataDir}/icon/"
ConfigPath = "#{DataDir}/json/"
CrewIcon = "#{PWAIconPath}/brew.png"

IconSearchGlob = [
  "#{SharePath}/icons/*/*/*/%s",
  "#{SharePath}/pixmaps/%s",
  "#{PWAIconPath}/%s"
]

HELP = <<EOF
crew-launcher: Add Chromebrew applications to launcher

Usage:
  new <pkgname|*.desktop file>     add an application to launcher
  remove <pkgname|*.desktop file>  remove existing profile(s) for application(s)
  stop-server                      stop launcher server if running
  start-server                     start launcher server for shortcut
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
