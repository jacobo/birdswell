require 'webrick'
server = WEBrick::HTTPServer.new :Port => 1234
server.mount "/", WEBrick::HTTPServlet::FileHandler, './birdswell'
trap('INT') { server.stop }
server.start
