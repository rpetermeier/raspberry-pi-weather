require 'rubygems'
require 'rufus/scheduler'

require_relative 'mock-meter.rb'

class WeatherStation
  
  attr_accessor :meter
  
  def initialize
    @meter = MockMeter.new
    @meter_values = Array.new
  end
  
  def start
    zero = Time.utc(1970, "jan", 1, 0, 0, 0)
    scheduler = Rufus::Scheduler.start_new
    scheduler.every '5s' do
      read_and_process_meter_value
    end
    
    scheduler.every '15s' do
      puts "#{Time.now.asctime}: still alive..."
    end
    puts "start: periodical reading of meter values has been scheduled."
    scheduler.join
  end
  
  def read_and_process_meter_value
    now = Time.now
    if @meter_values.size > 0 then
      if now - @meter_values[0].timestamp >= 2 * 60 then
        persist_meter_values(@meter_values)
        @meter_values = Array.new
      end
    end
    @meter_values.push(build_meter_value(meter.read, now))
  end
  
  def build_meter_value(meter_value_raw, now)
    MeterValue.new("#{(now.to_i) * 1000}\t#{meter_value_raw}", now)
  end
  
  def persist_meter_values(meter_values)
    puts "-----"
    puts "#{Time.now.asctime}: printing #{meter_values.size} values..."
    meter_values.each do |mv|
      puts "  #{mv}"
    end
    puts "-----" 
  end
  
end

class MeterValue
  attr_accessor :value
  attr_accessor :timestamp
  def initialize(value, timestamp)
    self.value = value
    self.timestamp = timestamp
  end
  
  def to_s
    "#{value}\t#{timestamp.asctime}"
  end

end

ws = WeatherStation.new
ws.start
