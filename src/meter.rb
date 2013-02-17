class Meter
  
  def read
    `/home/pi/software/SHT21/Raspi-SHT21-V3_0_0/sht21 S`.chomp
    # `ruby -v`.chomp
  end
  
end