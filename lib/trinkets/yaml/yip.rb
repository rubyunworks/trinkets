
module YIP

  def self.merge( str )
    str.gsub!(/<<:\s*\%FILE\((.*?)\)/) do |md|
      file = md[1]
      if File.file?(file)
        File.read(file)
      else
        nil
      end
    end
  end

end
