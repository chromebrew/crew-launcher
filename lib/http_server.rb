require 'socket'
require 'uri'

MimeType = {
  '.js' => 'application/javascript',
  '.json' => 'application/json',
  '.html' => 'text/html',
  '.png' => 'image/png',
  '.svg' => 'image/svg+xml',
}

def HTTPHeader (status_code, content_type = 'text/plain', extra = nil)
  status_msg = begin
    case status_code
    when 503
      'Service Unavailable'
    when 404
      'Not Found'
    when 200
      'OK'
    end
  end

  return <<~EOT.encode(crlf_newline: true)
    HTTP/1.1 #{status_code} #{status_msg}
    Content-Type: #{content_type}
    #{"#{extra}\n" if extra}
  EOT
end

module HTTPServer
  def self.start(port = Port, &block)
    server = TCPServer.new('localhost', port)
    # add REUSEADDR option to prevent kernel from keeping the port
    server.setsockopt(:SOCKET, :REUSEADDR, true)

    begin
      Socket.accept_loop(server) do |sock, _|
        begin
          request = sock.gets
          next unless request # undefined method `split' for nil:NilClass

          method, path, _ = request.split(' ', 3)
          uri = URI(path)
          yield sock, uri, method
        rescue Errno::EPIPE
        ensure
          sock.close
        end
      end
    ensure
      server.close
    end
  end
end
