#!/usr/bin/env ruby
# - * - coding: UTF-8 - * -

require 'socket'
require 'uri'
require 'json'
require 'securerandom'
require_relative 'lib/const'

Dir.glob('lib/*.rb') do |file|
  require_relative file
end

def stopExistingDaemon
  # kill existing server daemon
  begin
    if File.exist?("#{CacheDir}/daemon.pid")
      daemon_pid = File.read("#{CacheDir}/daemon.pid").to_i
      Process.kill(15, daemon_pid)
    end
  rescue Errno::ESRCH
  end
end

def CreateProfile(cmd = nil, filename: nil)
  # convert parsed hash into json format
  desktop = DesktopFile.parse( DesktopFile.find((filename || cmd)) )

  uuid = SecureRandom.uuid
  iconPath, iconSize, iconType = IconFinder.find(desktop['Desktop Entry']['Icon'])
  profile = {
    background_color: "black",
    theme_color: "black",
    name: desktop['Desktop Entry']['Name'],
    short_name: desktop['Desktop Entry']['GenericName'],
    description: desktop['Desktop Entry']['Comment'],
    start_url: "/#{uuid}/run",
    scope: "/#{uuid}/",
    display: "standalone",
    exec: desktop['Desktop Entry']['Exec'].sub(/%[A-Za-z]/, ''),
    icons: [
      {
        src: "/#{uuid}/appicon",
        path: iconPath,
        sizes: iconSize,
        type: iconType
      }
    ],
    shortcuts:
      desktop.select {|k, v| k =~ /^Desktop Action/ } .map do |k, v|
        action = k.scan(/^Desktop Action (.*)$/)[0][0]
        url = "/#{uuid}/run?shortcut=#{action}"
        exec = v['Exec'].sub(/%[A-Za-z]/, '')
        { action: action, name: v['Name'], url: url, exec: exec}
      end
  }
  
  duplicate_profile = `grep -lR "'exec': '#{profile[:exec]}'" #{ConfigPath}/*.json`.strip
  File.remove(duplicate_profile) unless duplicate_profile.empty?

  File.write("#{ConfigPath}/#{uuid}.json", profile.to_json)
  return uuid, profile
end

def InstallPWA (cmd)
  uuid, manifest = CreateProfile(cmd)
  # open a new tab in Chrome OS using dbus
  system 'dbus-send',
         '--system',
         '--type=method_call',
         '--print-reply',
         '--dest=org.chromium.UrlHandlerService',
         '/org/chromium/UrlHandlerService',
         'org.chromium.UrlHandlerServiceInterface.OpenUrl',
         "string:http://localhost:#{Port}/#{uuid}/installer.html"

  HTTPServer.start do |sock, uri, method|
    filename = File.basename(uri.path)

    case filename
    when 'manifest.webmanifest'
      sock.print HTTPHeader(200, 'application/manifest+json')
      sock.write File.read("#{ConfigPath}/#{uuid}.json")
    when 'appicon'
      sock.print HTTPHeader(200, manifest[:icons][0][:type])
      sock.write File.binread(manifest[:icons][0][:path])
    when 'stop'
      sock.print HTTPHeader(200)
      return
    else
      # search requested file in `pwa/` directory
      if File.file?("pwa/#{filename}")
        sock.print HTTPHeader(200, MimeType[ File.extname(filename) ])
        sock.write File.read("pwa/#{filename}")
      else
        sock.print HTTPHeader(404)
      end
    end
  end
end

def StartWebDaemon
  def LaunchApp(uuid, shortcut: false)
    file = "#{ConfigPath}/#{uuid}.json"

    unless File.exist?(file)
      error "#{uuid}: Profile not found!"
      retuen false
    end

    if Args['use-wayland']
      wm_type = 'wayland'
      ENV['WAYLAND_DISPLAY'] ||= 'wayland-0'
    else
      wm_type = 'x11'
      ENV['DISPLAY'] ||= ':0'
    end

    ENV['GDK_BACKEND'] = ENV['CLUTTER_BACKEND'] = wm_type

    profile = JSON.parse(File.read(file), symbolize_names: true)

    if shortcut
      cmd = profile[:shortcuts].select {|h| h[:action] == shortcut} [0][:exec]
    else
      cmd = profile[:exec]
    end
    
    log = File.open("#{CacheDir}/log/cmd/#{uuid}.log", 'w')
    spawn(ENV, cmd, {[:out, :err] => log})
  end

  # turn into a background procss
  Process.daemon(true)
  File.write("#{CacheDir}/daemon.pid", Process.pid)

  # redirect output to log
  log = File.open("#{CacheDir}/log/daemon.log", 'w')
  STDOUT.reopen(log)
  STDERR.reopen(log)

  #p "#{CacheDir}/pwa-daemon.pid"
  HTTPServer.start do |sock, uri, method|
    _, uuid, action = uri.path.split('/', 3)
    params = URI.decode_www_form(uri.query.to_s).to_h

    unless File.exist?("#{ConfigPath}/#{uuid}.json")
      sock.print HTTPHeader(404)
      next
    end

    case action
    when 'run'
      LaunchApp(uuid, shortcut: params['shortcut'])
      sock.print HTTPHeader(200, 'text/html')
      sock.write File.read('pwa/app.html')
    when 'stop'
      sock.print HTTPHeader(200)
      sock.print 'Server terminated: User interrupt.'
      exit 0
    end
  end
end

case ARGV[0]
when 'new'
  stopExistingDaemon()
  InstallPWA(ARGV[1])
  StartWebDaemon()
when 'server'
  stopExistingDaemon()
  StartWebDaemon()
when 'remove'
  file = `grep -lR "'exec': '#{ARGV[1]} .*'" #{ConfigPath}/*.json`.strip

  unless file.empty?
    File.remove(file)
  else
    error "Error: Cannot find a profile for #{ARGV[1]} :/"
  end
when 'uuid'
  puts `grep -lR "'exec': '#{ARGV[1]} .*'" #{ConfigPath}/*.json`.lines.first.lightblue
end
