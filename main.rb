#!/usr/bin/env ruby
# - * - coding: UTF-8 - * -

require 'fileutils'
require 'socket'
require 'uri'
require 'json'
require 'securerandom'
require_relative 'lib/const'
require_relative "#{CREW_PREFIX}/lib/crew/lib/color"
require_relative 'lib/desktop_file'
require_relative 'lib/function'
require_relative 'lib/http_server'
require_relative 'lib/icon_finder'

FileUtils.mkdir_p [ "#{TmpDir}/cmdlog/", ConfigPath ]

def getUUID (arg)
  # get desktop entry file path from package's filelist if a package name is given
  if arg[0] != '/'
    file = DesktopFile.find(arg)
  else
    file = arg
  end

  matched_file = `grep -l "\\"desktop_entry_file\\":\\"#{file}\\"" #{ConfigPath}/*.json 2> /dev/null`.lines(chomp: true)
  return File.basename(matched_file[0], '.json') if matched_file.any?
end

def stopExistingDaemon
  # kill existing server daemon
  begin
    if File.exist?("#{TmpDir}/daemon.pid")
      daemon_pid = File.read("#{TmpDir}/daemon.pid").to_i
      Process.kill(15, daemon_pid)
      puts "Server daemon PID #{daemon_pid} stopped.".lightgreen
    end
  rescue Errno::ESRCH
  end
end

def CreateProfile(arg)
  # get desktop entry file path from package's filelist if a package name is given
  if arg[0] != '/'
    file = DesktopFile.find(arg)
  else
    file = arg
  end

  abort "crew-launcher: No such file or directory -- '#{file}'".lightred unless File.exist?(file)
  # convert parsed hash into json format
  desktop = DesktopFile.parse(file)

  duplicate_profile_uuid = getUUID(file)

  if Args['update'] and duplicate_profile_uuid
    uuid = duplicate_profile_uuid
  else
    uuid = SecureRandom.uuid
    File.remove("#{ConfigPath}/#{duplicate_profile_uuid}.json") if duplicate_profile_uuid
  end

  iconPath, iconSize, iconType = IconFinder.find(desktop['Desktop Entry']['Icon'])
  profile = {
    desktop_entry_file: "#{file}",
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
 
  File.write("#{ConfigPath}/#{uuid}.json", profile.to_json)
  return uuid, profile
end

def InstallPWA (file)
  uuid, manifest = CreateProfile(file)
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
      if File.file?("#{LibPath}/pwa/#{filename}")
        sock.print HTTPHeader(200, MimeType[ File.extname(filename) ])
        sock.write File.read("#{LibPath}/pwa/#{filename}")
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

    profile = JSON.parse(File.read(file), symbolize_names: true)

    if shortcut
      cmd = profile[:shortcuts].select {|h| h[:action] == shortcut} [0][:exec]
    else
      cmd = profile[:exec]
    end

    log = "#{TmpDir}/cmdlog/#{uuid}.log"
    spawn(cmd, {[:out, :err] => File.open(log, 'w')})

    puts <<~EOT, nil
      Profile: #{files.queeze('/')}
      CmdLine: #{cmd.queeze('/')}
      Output: #{log.queeze('/')}
    EOT
  end

  puts "Server daemon PID #{Process.pid} started.".lightgreen

  # turn into a background procss
  Process.daemon(true, true)

  # redirect output to log
  log = File.open("#{TmpDir}/daemon.log", 'w')
  log.sync = true
  STDOUT.reopen(log)
  STDERR.reopen(log)

  puts "Daemon running with PID #{Process.pid}", nil
  File.write("#{TmpDir}/daemon.pid", Process.pid)

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
      sock.write File.read("#{LibPath}/pwa/app.html")
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
when 'start-server'
  stopExistingDaemon()
  StartWebDaemon()
when 'stop-server'
  stopExistingDaemon()
when 'remove'
  uuid = getUUID(ARGV[1])

  if uuid
    File.delete("#{ConfigPath}/#{uuid}.json")
  else
    error "Error: Cannot find a profile for #{ARGV[1]} :/"
  end
when 'uuid'
  ARGV.drop(1).each do |arg|
    if (uuid = getUUID(arg))
      puts uuid
    else
      error "#{arg}: No matching profile found."
    end
  end
when 'help', 'h', nil
  puts HELP
else
  print <<~EOT.lightred
    crew-launcher: invalid option '#{ARGV[0]}'
    Run `crew-launcher help` for more information.
  EOT
end
