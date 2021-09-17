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

DesktopSearchGlob = [
  "#{SharePath}/applications/%s.desktop"
]

IconSearchGlob = [
  "#{SharePath}/icons/*/*/*/%s",
  "#{SharePath}/pixmaps/%s",
  "#{PWAIconPath}/%s"
]

HELP = <<EOF
crew-launcher: Add Linux applications to Chrome OS launcher

Usage:
  new <desktop entry file>     add an application to launcher
  remove <desktop entry file>  remove existing profile(s) for application(s)
  stop                         stop launcher server if running
  start                        start launcher server for shortcut
  help                         show this message
  uuid <desktop entry file>    returns the UUID of specific profile(s)
EOF

# get locale settings from LC_MESSAGES env variable
unless ENV['LC_MESSAGES'].to_s.empty?
  LC_MESSAGES = ENV['LC_MESSAGES'].scan(/([\._@]?)([^\._@]+)/).to_h
  Locale = { lang: LC_MESSAGES[''], country: LC_MESSAGES['_'], modifier: LC_MESSAGES['@'] }
else
  Locale = nil
end
