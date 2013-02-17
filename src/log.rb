class Log

  def log(message)
    puts "#{Time.now.asctime}: #{message}"
  end

end