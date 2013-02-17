require 'socket'
require 'rubygems'
require 'rufus/scheduler'

require_relative 'log.rb'
require_relative 'platform.rb'
require_relative 'mock-meter.rb'
require_relative 'meter.rb'

module ImperialWeatherControl

  # Persist values every 30 minutes
  # PERSIST_INTERVAL = 5 * 60
  PERSIST_INTERVAL_SECONDS = 30 * 60

  # Read the meter every minute  
  # METER_READ_INTERVAL = '30s'
  METER_READ_INTERVAL = '1m'
  
  IS_ALIVE_INTERVAL = '180s'
  
  MANAGEMENT_PORT = 30023
  
  class WeatherStation
    
    attr_accessor :meter
    
    def initialize
      @log = Log.new
      if Platform.linux? then
        @meter = Meter.new
      else
        @meter = MockMeter.new
      end
      @meter_values = Array.new
    end
    
    def start
      @log.log "start: Raspberry Pi weather station is starting..."
      scheduler = Rufus::Scheduler.start_new
      @reader_job = scheduler.every METER_READ_INTERVAL do
        read_and_process_meter_value
      end
      
      @is_alive_job = scheduler.every IS_ALIVE_INTERVAL do
        @log.log "WeatherStation: I am still alive..."
      end      
      start_tcp_mgmt_server
      @log.log "start: periodical reading of meter values has been scheduled. Raspberry Pi weather station is operational."
      scheduler.join
    end

private

    def start_tcp_mgmt_server
      @log.log "start_tcp_mgmt_server: Starting TCP server for receiving management commands..."
      server = TCPServer.new("localhost", MANAGEMENT_PORT)
      @server_thread = Thread.start do
        @log.log "start_tcp_mgmt_server: Accepting connections on port #{MANAGEMENT_PORT}..."
        loop do
          client = server.accept
          @log.log '<mgmt interface>: a client has connected, reading command...'
          command = client.gets 
          client.close
          on_mgmt_command command
        end
      end
      @log.log "start_tcp_mgmt_server:: TCP server is now listening on port #{MANAGEMENT_PORT}"
    end
    
    def on_mgmt_command(command)
      if command.chomp == ":shutdown" then
        shutdown
      else
        @log.log "on_mgmt_command: Received unknown command #{command.to_s} via TCP. Will be ignored."
      end
    end
    
    def shutdown
      @log.log "shutdown: Received :shutdown command via TCP. Shutting down..."
      @reader_job.unschedule
      # @is_alive_job.unschedule      @log.log 'shutdown: Jobs have been unscheduled. Flushing any pending data records to a file...'
      persist_meter_values(@meter_values)
      @log.log 'shutdown: Data has been flushed to file. Calling exit...'

      # Killing the server thread doesn't work, neither in this thread (which is the server
      # thread) nor in another. Let's exit the hard way.
      # Thread.start do
      #  @server_thread.kill
      # end
      exit
    end
    
    def read_and_process_meter_value
      now = Time.now
      if @meter_values.size > 0 then
        if now - @meter_values[0].timestamp >= PERSIST_INTERVAL_SECONDS then
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
      if meter_values.size > 0 then
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
        @log.log "persist_meter_values: Persisted #{meter_values.size} values to file #{filename}"
      end
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

end
