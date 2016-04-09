require 'socket'
require 'uri'

host = "localhost"
port = 4040

@root = './html'

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
#def list_files(folder)
#  files = Dir["#{folder}"]
#  for i in files do
#  return "<br><a href='#{i}'>#{i}</a>\n"
#  end
#end

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
       IO.copy_stream(file, socket)
     end
   elsif File.file?(@root + "/index.html") == true
       File.open("#{@root}/index.html", "rb") do |file|
         puts what_type(file)
         puts file.size
         socket.print "HTTP/1.1 200 OK\r\n" +
                       "Content-Type: #{what_type(file)}\r\n" +
                       "Content-Length: #{file.size}\r\n" +
                       "Connection: close\r\n"
         socket.print "\r\n"
         IO.copy_stream(file, socket)
         end
   elsif Dir.entries(@root).size > 2 == true
       list_files(@root)
       socket.print "HTTP/1.1 404 Not Found\r\n" +
                    "Content-Type: text/html\r\n" +
                    "Content-Length: #{@message.size}\r\n" +
                    "Connection: close\r\n"

       socket.print "\r\n"
       socket.print @message

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
