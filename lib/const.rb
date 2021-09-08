Args = ARGV.grep(/^--/).map do |arg|
  [ arg.sub('--', ''), true ]
end.to_h

Port = 25500
CREW_PREFIX = (ENV['CREW_PREFIX'].to_s.empty?) ? '/usr/local' : ENV['CREW_PREFIX']
LibPath = File.expand_path('..', __dir__)
SharePath = "#{CREW_PREFIX}/share/"
TmpDir = "/tmp/crew-integration/"
DataDir = "#{SharePath}/crew-integration/"
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
  stop            stop launcher server if running
  start           start launcher server for shortcut
  help            show this message
  new <command>   add an applications to launcher
EOF

# get locale settings from LC_MESSAGES env variable
unless ENV['LC_MESSAGES'].to_s.empty?
  LC_MESSAGES = ENV['LC_MESSAGES'].scan(/([\._@]?)([^\._@]+)/).to_h
  Locale = { lang: LC_MESSAGES[''], country: LC_MESSAGES['_'], modifier: LC_MESSAGES['@'] }
else
  Locale = nil
end
