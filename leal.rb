require 'socket'
require 'uri'

host = "localhost"
port = 4040

@root = './html'

CONTENT_TYPES = {
  'html' => 'text/html',
  'txt' => 'text/plain',
  'gif' => 'image/gif',
  'png' => 'image/png',
  'jpg' => 'image/jpeg',
  'pdf' => 'application/pdf'
}

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
  parts = path.split("/")   # Split the path into components
  parts.each do |part| # skip any empty or current directory (".") path components
    next if part.empty? || part == '.'
   # If the path component goes up one directory level (".."),
   # remove the last clean component.
   # Otherwise, add the component to the Array of clean components
    part == '..' ? clean.pop : clean << part
  end
  File.join(@root, *clean) # return the web root joined to the clean path
end

server = TCPServer.new(host, port)
loop do
  Thread.start(server.accept) do |socket|
   request_line = socket.gets
   STDERR.puts request_line
   path = requested_file(request_line)
   puts path
   if File.exist?(path) && !File.directory?(path)
     File.open(path, "rb") do |file|
       puts what_type(file)
       puts file.size
       socket.print "HTTP/1.1 200 OK\r\n" +
                     "Content-Type: #{what_type(file)}\r\n" +
                     "Content-Length: #{file.size}\r\n" +
                     "Connection: close\r\n"
       socket.print "\r\n"
       #socket.print(file)
       IO.copy_stream(file, socket)
     end
     else
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
      socket.close
    end
end



#def list_files(folder)
#  @files = Dir.entries(folder)
#  @files -= %w{.. .}
#  @content = "Directory Index\n"
#  puts @files
#  for i in @files do
#    @content << "<br><a href='#{i}'>#{i}</a>\n"
#  end
#  puts @content
#end

#if Dir.entries(@folder).include?('index.html') == true
#  @content_type = "text/html"
#  @content = File.read("#{@folder}/index.html")
#else
#  list_files(@folder)
#end
