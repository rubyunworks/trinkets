# CloseCall
# by Derek Lewis <lewisd#f00f.net>

# Mixin that allows programs to make slight spelling and/or arity mistakes on 
# method calls and the program will still work. It achieves this by applying 
# some hueristics in method_missing. It searches all the methods on the object
# with the same (or compatible) arity, and uses the String#fuzzy_match method
# from the code snippets on rubyforge to find a method with a similar name. 
# When it finds one similar enough, it uses class_eval to define the method,
# so method_missing doesn't get called the next time.
#
# This is highly experimental, and is here primarily for expirementation with 
# Natural Langauge Computing.

module CloseCall

  MIN_SCORE = 0.75

  def find_similar_symbol(symbol, args)
    methods = self.public_methods.find_all do |sym|
      arity = self.method(sym).arity
      arity < 0 || arity == args
    end
    #p methods
    method,score = best_match(symbol, methods)
    #puts "Method: #{method}   Score: #{score}"
    return method if (score > MIN_SCORE)
    puts "Score = #{score}"
    return nil
  end

  def best_match(name, things)
    high_score = -1
    high_match = nil
    name = name.to_s
    things.each do |thing|
      str = thing.to_str
      if str != nil
        #puts "Checking #{str}"
        score = str.fuzzy_match(name)
        if (score > high_score)
          high_score = score
          high_match = thing
        end
      end
    end
    return high_match, high_score
  end

  def method_missing(symbol, *args)
    puts "Finding method for #{symbol} with #{args.length} args"
    sym = find_similar_symbol(symbol, args.length)
    if sym != nil
      method = method(sym)
      max_arity = self.public_methods.collect{|sym| self.method(sym).arity}.sort.last
      if !self.respond_to?(symbol)
        code = %'
          def #{symbol}(*args)
            case args.length'
        0.upto(max_arity) do |x|
          sym = find_similar_symbol(symbol, x);
          if (sym != nil)
            code += %'
            when #{x}
              if block_given?
                #{sym}(*args) { |*bargs| yield *bargs }
              else
                #{sym}(*args)
              end'
          end
        end
        code = code + %'
            else
              raise NameError, "no method similar to \'#{symbol}\' found for \#{args.length} args"
            end
          end'
        #puts code
        puts "defining method for #{symbol}"
        self.class.class_eval code
      end
      return self.send(symbol, *args) { |*bargs| yield *bargs }
    end
    raise NameError, "no method similar to `#{symbol}' with #{args.length} args for \"#{self}\":#{self.class}"
  end

  private :find_similar_symbol, :best_match

end

class String

  # A fuzzy matching mechanism. Returns a score from 0-1,
  # based on the number of shared edges.
  # To be effective, the strings must be of length 2 or greater.
  #
  #   "Alexsander".fuzzy_match( "Aleksander" )  #=> 0.9
  #
  # The way it works:
  #
  # * Converts each string into a "graph like" object, with edges
  #     "alexsander" -> [ alexsander, alexsand, alexsan ... lexsand ... san ... an, etc ]
  #     "aleksander" -> [ aleksander, aleksand ... etc. ]
  # * Perform match, then remove any subsets from this matched set (i.e. a hit
  #   on "san" is a subset of a hit on "sander")
  #     Above example, once reduced -> [ ale, sander ]
  # * See's how many of the matches remain, and calculates a score based
  #   on how many matches, their length, and compare to the length of the
  #   larger of the two words.
  #
  # Still a bit rough. Any suggestions for improvement are welcome.
  #
  def fuzzy_match( str_in )
    return 0 if str_in == nil
    return 1 if self == str_in

    # Make a graph of each word (okay, so its not a true graph, but is similar)
    graph_A = Array.new
    graph_B = Array.new

    # "graph" self
    last = self.length
    (0..last).each do |ff|
      loc  = self.length
      break if ff == last - 1
      wordB = (1..(last-1)).to_a.reverse!
      if (wordB != nil)
        wordB.each do |ss|
          break if ss == ff
          graph_A.push( "#{self[ff..ss]}" )
        end
      end
    end

    # "graph" input string
    last = str_in.length
    (0..last).each{ |ff|
      loc  = str_in.length
      break if ff == last - 1
      wordB = (1..(last-1)).to_a.reverse!
      wordB.each do |ss|
        break if ss == ff
        graph_B.push( "#{str_in[ff..ss]}" )
      end
    }

    # count how many of these "graph edges" we have that are the same
    matches = graph_A & graph_B
    #matches = Array.new
    #graph_A.each do |aa|
    #  matches.push( aa ) if( graph_B.include?( aa ) )
    #end

    # For eliminating subsets, we want to start with the smallest hits.
    matches.sort!{|x,y| x.length <=> y.length}

    # eliminate any subsets
    mclone = matches.dup
    mclone.each_index do |ii|
      reg = Regexp.compile( Regexp.escape(mclone[ii]) )
      count = 0.0
      matches.each{|xx| count += 1 if xx =~ reg}
      matches.delete(mclone[ii]) if count > 1
    end

    score = 0.0
    matches.each{ |mm| score += mm.length }
    self.length > str_in.length ? largest = self.length : largest = str_in.length
    return score/largest
  end

end

