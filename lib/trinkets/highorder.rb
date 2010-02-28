require 'facets/functor'


#

class HigherOrderMessage
  def HigherOrderMessage.is_vital(method)
    return method =~ /__(.+)__|method_missing/
  end

  for method in instance_methods
    undef_method(method) unless is_vital(method)
  end

  def initialize(handler)
    @handler = handler
  end

end


  # "Do" sends the captured message to all elements of a collection and returns nil:

  class Do < HigherOrderMessage
    def method_missing(id, *args)
      @handler.each {|e| e.__send__(id,*args)}
      return nil
    end
  end

  # "Where" selects elements of a collection for which the captured message returns true:

  class Where < HigherOrderMessage
    def method_missing(id, *args)
      return @handler.select {|e| e.__send__(id,*args)}
    end
  end

  #

  class Are < HigherOrderMessage
    def method_missing(id, *args)
      return @handler.apply {|e| e.__send__(id,*args)}
    end
  end

  class AreNot < HigherOrderMessage
    def method_missing(id, *args)
      return @handler.apply {|e| not e.__send__(id,*args)}
    end
  end


#

class Collator
  def initialize(receiver)
    @receiver = receiver
  end

  def are
    Are.new(self)
  end

  def are_not
    AreNot.new(self)
  end

end

  class That < Collator
    def apply(&block)
      return @receiver.select(&block)
    end
  end

  class Which < Collator
    def apply(&block)
      return @receiver.select(&block)
    end
  end

  class All < Collator
    def apply(&block)
      return @receiver.all?(&block)
    end
  end

  class Any < Collator
    def apply(&block)
      return @receiver.any?(&block)
    end
  end

end





#I can then add these higher order messages to all enumerable objects by adding them to the Enumerable mix-in:

module Enumerable
  def do1
    @_do ||= Do.new(self)
  end

  def where1
    @_where ||= Where.new(self)
  end
end





module Enumerable
  def do
    Functor.new do |id, *args|
      each {|e| e.__send__(id,*args)}
      nil
    end
  end

  def where
    Functor.new do |id, *args|
      select {|e| e.__send__(id,*args)}
    end
  end
end

p (1..10).where1 > 2
p (1..10).where2 > 2

require 'benchmark'

n = 5000
Benchmark.bm(10) do |x|
  x.report("where:")  { n.times do ; r = (1..10).where1 > 2 ; end }
  x.report("where2:") { n.times do ; r = (1..10).where2 > 2 ; end }
end
