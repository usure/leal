#!/usr/bin/env ruby
#/ Usage: <leal> [-h][-p] [-l] [--f]
$stderr.sync = true
require 'optparse'
require 'socket'
require 'date'
require 'uri'

host = "localhost"
port = 4040
@log_file = "server.log"
@root = './html'

file = __FILE__
ARGV.options do |opts|
  opts.on("-h", "--hostname=val", String)   { |val| host = val }
  opts.on("-p", "--port=val", Integer)     { |val| port = val }
  opts.on("-l", "--log=val", String)     { |val| if val == "none" then @log_file = nil else @log_file = val end }
  opts.on("-f", "--folder=val", String) {|val| @root = val}
  opts.on_tail("--help")         { exec "grep ^#/<'#{file}'|cut -c4-" }
  opts.parse!
end

CONTENT_TYPES = {
  'html' => 'text/html',
  'sh' => 'application/x-sh',
  'txt' => 'text/plain',
  'js'  => 'application/javascript',
  'gif' => 'image/gif',
  'png' => 'image/png',
  'jpg' => 'image/jpeg',
  'weba' => 'audio/webm',
  'webm' => 'video/webm',
  'mp3' => 'audio/mpeg',
  'ogg' => 'application/ogg',
  'zip' => 'application/zip',
  'rar' => 'application/x-rar-compressed',
  'deb' => 'application/x-debian-package',
  'tar' => 'application/x-tar',
  'bz2' => 'application/x-bzip2',
  'bz'  => 'application/x-bzip',
  'xml' => 'application/xml',
  'pdf' => 'application/pdf'
}

RESPONSE_CODES = { ########################## UNUSED. KEEP AS PLACEHOLDER
  404 => 'Not Found',
  200 => 'OK',
  201 => 'Created',
  301 => 'Moved Permanently',
  400 => 'Bad Request',
  402 => 'Payment Required',
  403 => 'Forbidden',
  429 => 'Too Many Request',
  451 => 'Unavailable For Legal Reasons'
}

def log(something)
  file = IO.sysopen @log_file, "a+"
  ios = IO.new(file, "a+")
  ios.puts(something)
  ios.close
end

def list_files(folder)
  @message = """<html><head>
 <title>Index of #{folder}</title>
 </head>
 <body>
 <br><b>Index of #{folder}</b>"""
  Dir.foreach(folder) do |item|
    next if item == '.' or item == '..'
    l_mtime = File.mtime("#{folder}/#{item}").to_s
    @message << "<br><a href='#{item}'>#{item}</a> <i>#{l_mtime}</i>\n"
  end
  @message << "</pre></body></html>"
  return @message
end

def what_type(file_name)
  ext = File.extname(file_name)
  ext = ext.sub(/^./, '')

  if CONTENT_TYPES.has_key?(ext) == false
    return 'application/octet-stream'
  else
    return CONTENT_TYPES.fetch(ext)
  end
end

def requested_file(request_line)
  request_uri  = request_line.split(" ")[1]
  path         = URI.unescape(URI(request_uri).path)
  clean = []
  parts = path.split("/")
  parts.each do |part|
    next if part.empty? || part == '.'
    part == '..' ? clean.pop : clean << part
  end
  File.join(@root, *clean)
end

server = TCPServer.new(host, port)
puts "server started at #{host}:#{port}" # not exact
loop do
  Thread.start(server.accept) do |socket|
   request_line = socket.gets
   log(request_line)
   #STDERR.puts request_line
   path = requested_file(request_line)
   log(path + " #{DateTime.now().to_s}")
   #puts path
   #remote_port, remote_hostname, remote_ip = socket.peeraddr
   log("#{socket.peeraddr[3]}:#{socket.peeraddr[1]} #{DateTime.now().to_s}")
   if File.exist?(path) && !File.directory?(path)
     File.open(path, "rb") do |file|
       puts what_type(file)
       puts file.size
       socket.print "HTTP/1.1 200 OK\r\n" +
                     "Last-Modified: #{File.mtime(file)}\r\n" +
                     "Content-Type: #{what_type(file)}\r\n" +
                     "Content-Length: #{file.size}\r\n" +
                     "Connection: close\r\n"
       socket.print "\r\n"
       IO.copy_stream(file, socket)
     end
   elsif File.file?(@root + "/index.html") == true && !File.exist?(path) == false
       File.open("#{@root}/index.html", "rb") do |file|
         puts what_type(file)
         puts file.size
         socket.print "HTTP/1.1 200 OK\r\n" +
                       "Last-Modified: #{File.mtime(file)}\r\n" +
                       "Content-Type: #{what_type(file)}\r\n" +
                       "Content-Length: #{file.size}\r\n" +
                       "Connection: close\r\n"
         socket.print "\r\n"
         IO.copy_stream(file, socket)
      end
     elsif File.exist?(path) == false
       puts path

       message = %q( <html lang="en">
        <head>
         <title>404 - Not Found</title>
        </head>
        <body>
        <h1>404 - Not Found</h1>
        </body>
       </html>)

        STDERR.puts request_line
        # 404 error displayed
        socket.print "HTTP/1.1 404 Not Found\r\n" +
                     "Content-Type: text/html\r\n" +
                     "Content-Length: #{message.size}\r\n" +
                     "Connection: close\r\n"

        socket.print "\r\n"
        socket.print message
      end

      if Dir.entries(@root).size > 2 == true && File.exist?(@root + "/index.html") == false #### FIX THIS
          list_files(@root)
          socket.print "HTTP/1.1 200 OK\r\n" +
                       "Content-Type: text/html\r\n" +
                       "Content-Length: #{@message.size}\r\n" +
                       "Connection: close\r\n"

          socket.print "\r\n"
          socket.print @message
        end
      socket.close
    end
  end
