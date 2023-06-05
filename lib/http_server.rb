# http_server.rb: A simple HTTP server based on HTTP/1.1
require 'socket'
require 'uri'
require_relative 'const'

class TCPSocket
  def send_http_response(resp_code, data = nil, header: nil)
    raw_header = "HTTP/1.1 #{resp_code} #{HTTPServer::STATUS_CODE[resp_code]}\r\n"
    raw_header.concat <<~EOT.encode(crlf_newline: true)
      Connection: keep-alive
      Access-Control-Allow-Origin: http://localhost:25500
    EOT

    raw_header.concat("Content-Length: #{data ? data.bytesize : 0}\r\n")
    raw_header.concat(header.map {|k, v| "#{k}: #{v}" } .join("\r\n")) if header
    raw_header.concat("\r\n\r\n")

    warn "Respond with status #{resp_code} (#{HTTPServer::STATUS_CODE[resp_code]})"

    self.write(raw_header)
    self.write(data) if data
  end
end

class HTTPServer
  STATUS_CODE = {
    101 => 'Switching Protocols',
    200 => 'OK',
    403 => 'Forbidden',
    404 => 'Not Found',
    501 => 'Not Implemented'
  }

  MIME_TYPE = {
    '.js'   => 'application/javascript; charset=utf-8',
    '.json' => 'application/json; charset=utf-8',
    '.html' => 'text/html; charset=utf-8',
    '.css'  => 'text/css; charset=utf-8',
    '.svg'  => 'image/svg+xml',
    '.png'  => 'image/png'
  }

  def initialize(port = SERVER_PORT)
    @server = TCPServer.open('127.0.0.1', port)
    @handler = {}
  end

  def on_api(path, &handler)
    # on_api(): Add a handler function for path /api/#{path}
    @handler[path] = handler
  end

  def listen
    Socket.accept_loop(@server) do |sock, addr|
      Thread.new do
        puts 'New TCP connection opened'
        while (http_header = sock.gets("\r\n\r\n", chomp: true)&.lines(chomp: true))
          request_method, request_path, _ = http_header[0].split(' ', 3)
          header_field                    = http_header[1..-1].to_h {|field| field.split(': ', 2) }

          if header_field.key?('Origin') && header_field['Origin'] != 'http://localhost:25500'
            warn "Rejecting request from #{header_field['Origin']}"
            sock.send_http_response(403)
            break
          end

          uri    = URI.parse(request_path)
          params = URI.decode_www_form(uri.query || '').to_h
          puts "#{request_method} #{request_path} #{_}"

          if uri.path.start_with?('/static/') || uri.path.start_with?('/fs/')
            # read from filesystem directly if file exist
            if uri.path.start_with?('/static/')
              file_path = File.join(WEBSTATIC_DIR, uri.path.delete_prefix('/static/'))
            else
              file_path = uri.path.delete_prefix('/fs')
            end

            if File.exist?(file_path)
              sock.send_http_response(200, File.binread(file_path), header: {'Content-Type' => MIME_TYPE[File.extname(file_path)]})
            else
              sock.send_http_response(404)
            end
          elsif uri.path == '/sw.js'
            sock.send_http_response(200, File.binread(File.join(WEBSTATIC_DIR, 'js/sw.js')), header: {'Content-Type' => MIME_TYPE['.js']})
          elsif @handler.key?(uri.path[%r{/api/([^/]+)}, 1])
            # call API handler if defined
            @handler[uri.path[%r{/api/([^/]+)}, 1]].call(sock, uri.path[%r{/api/[^/]+(.+)}, 1], params, { method: request_method, header_field: header_field })
          else
            sock.send_http_response(404)
          end
        end
      ensure
        sock.close
      end
    end
  ensure
    @server.close
  end
end