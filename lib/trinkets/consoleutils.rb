
module ConsoleUtils

  # Convenient method to get simple console reply.

  def ask(question, answers=nil)
    print "#{question}"
    print " [#{answers}] " if answers
    until inp = $stdin.gets ; sleep 1 ; end
    inp
  end

  # Ask for a password. (FIXME: only for unix so far)

  def password(prompt=nil)
    msg ||= "Enter Password: "
    inp = ''

    print "#{prompt} "

    begin
      system "stty -echo"
      #inp = gets.chomp
      until inp = $stdin.gets
        sleep 1
      end
    ensure
      system "stty echo"
    end

    return inp.chomp
  end

end


class Array

  # Convert an array into command line parameters.
  # The array is accepted in the format of Ruby
  # method arguments --ie. [arg1, arg2, ..., hash]

  def to_params
    flags = (Hash===last ? pop : {})
    flags = flags.collect do |f,v|
      m = f.to_s.size == 1 ? '-' : '--'
      case v
      when Array
        v.collect{ |e| "#{m}#{f} '#{e}'" }.join(' ')
      when true
        "#{m}#{f}"
      when false, nil
        ''
      else
        "#{m}#{f} '#{v}'"
      end
    end
    return (flags + self).join(" ")
  end

  # Not empty?

  def not_empty?
    !empty?
  end

end
