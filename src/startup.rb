require_relative 'weather_station.rb'

Dir.chdir(File.dirname(__FILE__))
ws = ImperialWeatherControl::WeatherStation.new
ws.start