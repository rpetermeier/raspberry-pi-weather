require 'rubygems'
require 'rufus/scheduler'

require_relative 'mock-meter.rb'
require_relative 'meter.rb'

class WeatherStation
  
  attr_accessor :meter
  
  def initialize
    # @meter = MockMeter.new
    @meter = Meter.new
    @meter_values = Array.new
  end
  
  def start
    zero = Time.utc(1970, "jan", 1, 0, 0, 0)
    scheduler = Rufus::Scheduler.start_new
    # TODO: change to 1m
    scheduler.every '5s' do
      read_and_process_meter_value
    end

    puts "start: periodical reading of meter values has been scheduled."
    scheduler.join
  end
  
  def read_and_process_meter_value
    now = Time.now
    if @meter_values.size > 0 then
      # TODO: Change to 30 * 60 (create a file every 30 minutes)
      if now - @meter_values[0].timestamp >= 1 * 60 then
        persist_meter_values(@meter_values)
        @meter_values = Array.new
      end
    end
    @meter_values.push(build_meter_value(meter.read, now))
  end
  
  def build_meter_value(meter_value_raw, now)
    MeterValue.new(meter_value_raw, now)
  end
  
  def persist_meter_values(meter_values)
    # TODO: Delete printing of values
    print_meter_values(meter_values)
    
    Dir.mkdir("../out") unless FileTest.exists?("../out")
    
    first_ts = meter_values[0].timestamp
    first_ts.gmtime
    filename = first_ts.strftime("%Y-%m-%d_%H-%M.txt")
    filename_tmp = filename + ".tmp"
    File.open("../out/#{filename_tmp}", "w:utf-8") do |file|
      meter_values.each do |mv|
        file.write "#{(mv.timestamp.to_i * 1000).to_s}\t#{mv.value}\n"
      end
    end
    File.rename("../out/#{filename_tmp}", "../out/#{filename}")
  end
  
  # TODO: Delete printing of values
  def print_meter_values(meter_values)
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
  
  def to_s(debug = false)
    if (debug) then
      "#{value}\t#{timestamp.asctime}"
    else
      value.to_s
    end 
  end

end

Dir.chdir(File.dirname(__FILE__))
ws = WeatherStation.new
ws.start
