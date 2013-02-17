require 'socket'

socket = TCPSocket.new 'localhost', 30023

puts "Socket opened, sending :shutdown command"
socket.puts ":shutdown"
socket.close
puts ":shutdown command sent, socket has been closed."