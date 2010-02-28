class IO
  #

  def gets_max(max=2048)
    row = nil
    each_byte do |b|
      row = row.to_s + b.chr
      return row if b.chr == "\n"
      raise IOError.new("safe_gets: row too long (max=#{max})") if row.length > max
    end
    row
  end
end

