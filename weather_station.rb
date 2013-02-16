require 'rubygems'
require 'rufus/scheduler'

require_relative 'mock-meter.rb'

class WeatherStation
  
  attr_accessor :meter
  
  def initialize
    @meter = MockMeter.new
  end
  
  def start
    zero = Time.utc(1970, "jan", 1, 0, 0, 0)
    scheduler = Rufus::Scheduler.start_new
    scheduler.every '10s' do
      now = Time.now
      puts "#{(now.to_i) * 1000}\t#{meter.read}\t#{now.asctime}"
    end
    puts "start: periodical read of meter values has been scheduled."
    scheduler.join
  end
  
end

ws = WeatherStation.new
ws.start