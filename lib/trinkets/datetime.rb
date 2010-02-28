require 'date'
require 'parsedate'

class DateTime

  attr_accessor :year,
                :month,
                :day,
                :hour,
                :minute,
                :second,
                :microsecond,
                :timezone,
                :daylightsavings

  def initialize(*args)
    if args.length = 1 and args[0].kind_of?(String)
      pd = ParseDate.parsedate(args[0])
      @year = pd[0].to_i
      @month = pd[1].to_i
      @day = pd[2].to_i
      @hour = pd[3].to_i
      @minute = pd[4].to_i
      @second = pd[5].to_i
      @microsecond = pd[6].to_i
      @timezone = pd[7].to_i
      @daylightsavings = pd[8] ? true : false
    else
      @year = args[0].to_i
      @month = args[1].to_i
      @day = args[2].to_i
      @hour = args[3].to_i
      @minute = args[4].to_i
      @second = args[5].to_i
      @microsecond = args[6].to_i
      @timezone = args[7].to_i
      @daylightsavings = args[8] ? true : false
    end

  end

end