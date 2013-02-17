module Platform
  
  def Platform::linux?
    /linux/ =~ RUBY_PLATFORM
  end
  
end
