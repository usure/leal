require 'socket'

server = TCPServer.new('localhost', 4040)
@folder = "html/"

def list_files(folder)
  @files = Dir.entries(folder)
  @files -= %w{.. .}
  @content = "Directory Index\n"
  puts @files
  for i in @files do
    @content << "<br><a href='#{i}'>#{i}</a>\n"
  end
  puts @content
end

if Dir.entries(@folder).include?('index.html') == true
  @content = File.read("#{@folder}/index.html")
else
  list_files(@folder)
end


loop do
  Thread.start(server.accept) do |client|
   client.print "HTTP/1.1 200 OK\r\n" +
                 "Content-Type: text/html\r\n" +
                "Content-Length: #{@content.bytesize}\r\n" +
                 "Connection: close\r\n"
    client.print "\r\n"

    client.print @content
    client.close
  end
end
