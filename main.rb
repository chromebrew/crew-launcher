require 'json'
require_relative 'lib/color'
require_relative 'lib/const'
require_relative 'lib/desktop_entry'
require_relative 'lib/http_server'
require_relative 'lib/open_url'

def start_daemon
  daemon_pid = get_daemon_pid

  if daemon_pid
    warn "crew-launcher server daemon with PID #{daemon_pid} already running.".lightgreen
    return
  end

  Process.daemon(false, true)
  warn "crew-launcher server daemon with PID #{Process.pid} started.".lightgreen
  File.write(PID_FILE, Process.pid)

  # redirect output to log file
  logfile = File.open(LOG_FILE, 'w')
  $stdout.reopen(logfile)
  $stderr.reopen(logfile)
  $stdout.sync = $stderr.sync = true

  server = HTTPServer.new

  server.on_api('getAvailableEntries') do |sock, path, params, http_header|
    sock.send_http_response(200, DesktopEntry.get_available_apps.to_json, header: { 'Content-Type' => HTTPServer::MIME_TYPE['.json'] })
  end

  server.on_api('desktopEntry') do |sock, path, params, http_header|
    if File.exist?(path)
      entry = DesktopEntry.parse_entry(path)

      if params['action'] == 'startApp'
        sock.send_http_response(200, File.binread(File.join(WEBSTATIC_DIR, 'splash_screen.html')), header: { 'Content-Type' => HTTPServer::MIME_TYPE['.html'] })

        if params.key?('shortcut')
          spawn entry["Desktop Action #{params['shortcut']}"]['Exec'].gsub(/%[A-Za-z]/, '')
        else
          spawn entry['Desktop Entry']['Exec'].gsub(/%[A-Za-z]/, '')
        end
      elsif params['action'] == 'installApp'
        sock.send_http_response(200, File.binread(File.join(WEBSTATIC_DIR, 'installer.html')), header: { 'Content-Type' => HTTPServer::MIME_TYPE['.html'] })
      elsif params['action'] == 'getParsed'
        sock.send_http_response(200, entry.to_json, header: { 'Content-Type' => HTTPServer::MIME_TYPE['.json'] })
      else
        sock.send_http_response(501)
      end
    else
      sock.send_http_response(404)
    end
  end

  server.listen
end

def stop_daemon
  daemon_pid = get_daemon_pid
  if daemon_pid
    Process.kill(15, daemon_pid)
    warn "crew-launcher server daemon with PID #{daemon_pid} stopped.".lightred
  end
end

def get_daemon_pid
  if File.exist?(PID_FILE)
    begin
      daemon_pid = File.read(PID_FILE).to_i
      Process.kill(0, daemon_pid)
      return daemon_pid
    rescue Errno::ESRCH
    end
  end
  return false
end

case ARGV[0]
when 'add', 'new'
  if ARGV[1]
    if File.exist?(ARGV[1])
      open_url File.join("http://localhost:#{SERVER_PORT}/api/desktopEntry", File.expand_path(ARGV[1])) + '?action=installApp'
    else
      abort "#{$0}: #{ARGV[1]}: No such file or directory".lightred
    end
  else
    open_url "http://localhost:#{SERVER_PORT}/static/add2launcher.html"
  end
when 'start', 'start-server'
  start_daemon
when 'stop', 'stop-server'
  stop_daemon
when 'stat', 'status'
  daemon_pid = get_daemon_pid
  if daemon_pid
    puts "crew-launcher server daemon with PID #{daemon_pid} started.".lightgreen
  else
    puts "crew-launcher server daemon is not running.".lightred
  end
when 'open-ui'
  open_url "http://localhost:#{SERVER_PORT}/static/add2launcher.html"
when 'help', '--help', '-h'
  puts HELP
else
  warn <<~EOT
    #{$0}: invalid option: "#{ARGV[0]}"

    Run "#{$0} help" for more information.
  EOT
end