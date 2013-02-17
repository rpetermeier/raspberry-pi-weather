class MockMeter
  
  def read
    # "18.9\t36"
    `ruby -v`.chomp
  end
  
end