require 'socket'
require_relative 'weather_station.rb'

socket = TCPSocket.new 'localhost', ImperialWeatherControl::MANAGEMENT_PORT

puts "Socket opened, sending :shutdown command"
socket.puts ":shutdown"
socket.close
puts ":shutdown command sent, socket has been closed."