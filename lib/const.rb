CREW_PREFIX = (ENV['CREW_PREFIX'].to_s.empty?) ? '/usr/local' : ENV['CREW_PREFIX']
require_relative "#{CREW_PREFIX}/lib/crew/lib/color.rb"

Args = ARGV.grep(/^--/).map do |arg|
  [ arg.sub('--', ''), true ]
end.to_h

Port = 25500
SharePath = "#{CREW_PREFIX}/share/"
CacheDir = "#{ENV['XDG_CACHE_HOME']}/crew-integration"
DataDir = "#{ENV['XDG_CONFIG_HOME']}/crew-integration/"
PWAIconPath = "#{DataDir}/icon/"
ConfigPath = "#{DataDir}/json/"
CrewIcon = "#{PWAIconPath}/icons/brew.png"

DesktopSearchGlob = [
  "#{SharePath}/applications/%s.desktop"
]

IconSearchGlob = [
  "#{SharePath}/icons/*/*/*/%s",
  "#{SharePath}/pixmaps/%s",
  "#{PWAIconPath}/%s"
]

# get locale settings from LC_MESSAGES env variable
unless ENV['LC_MESSAGES'].to_s.empty?
  LC_MESSAGES = ENV['LC_MESSAGES'].scan(/([\._@]?)([^\._@]+)/).to_h
  Locale = { lang: LC_MESSAGES[''], country: LC_MESSAGES['_'], modifier: LC_MESSAGES['@'] }
else
  Locale = nil
end
