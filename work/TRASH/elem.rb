require 'benchmark'

require 'facets/functor'

require 'enumerator'

  # = Elementor
  #
  # Elementor is an a type of *functor*. Operations
  # applied to it are routed to each element.

  class Elementor
    # TODO Some methods to move aside for method_missing
    #private *instance_methods - ['inspect']

    def initialize(elem_object, elem_method=nil)
      @elem_object = elem_object
      @elem_method = elem_method || :map
      #super
    end

    def instance_delegate
      @elem_object
    end

    def instance_operator
      @elem_method
    end

    def to_a
      @elem_object.to_a
    end

    #def ==(other)
    #  instance_delegate == other.instance_delegate &&
    #  instance_operator == other.instance_operator
    #end

    def method_missing(sym,*args,&blk)
      @elem_object.send(@elem_method){ |x| x.send(sym,*args,&blk) }
    end
  end

class Elemental
  def initialize(elem_object)
    @elem_object = elem_object
  end
  def method_missing(enum_method)
    Elementor.new(@elem_object,enum_method)
  end
end

class Enumerable::Enumerator
  def every(&block)
    if block_given?
      each{ |x| x.instance_eval(&block) }
    else
      @_every ||= Functor.new do |op,*args|
        each{ |a| a.send(op,*args) }
      end
    end
  end
end

module Enumerable
  def elemental
    Elemental.new(self)
  end

  def and
    Elementor.new(self,:map)
  end

  def everywise
    @_everywise ||= (
      obj = self
      func = Functor.new do |op,*args|
        collect{ |a| a.send(op,*args) }.everywise
      end
      (class << func; self; end).send(:define_method,:to_a){ obj }
      func
    )
  end

  def every(&block)
    if block_given?
      map{ |x| x.instance_eval(&block) }
    else
      @_every ||= Elementor.new(self,:map) #Functor.new do |op,*args|
        #map{ |a| a.send(op,*args, &blk) }
      #end
    end
  end

  def queue(&block)
    map{|x|
      x.instance_eval(&block)
    }
  end

end

#to_elem(:map) + 3

p [1,2,3].elemental

p [1,2,3].elemental.map

p [1,2,3].elemental.map + 3

#p [1,2,3].map.it + 3
#p ['a','b','c'].map.it.upcase

e = ['a','b','c'].to_enum(:each)
p e
p e.to_enum(:each)

[[1,2,3],[4,5,6]].every.each{ |x| p x }

r = [1,2,3].every + 2

p r

#r = (['a','b','c'].everywise.upcase + '!')
#p r
#p r.to_a

#exit 0





class Elm
  def initialize(a,b)
    @a = a
    @b = b
  end
  def foo
    p @a
  end
  def bar
    p @b
  end
  def method_missing(s,*a, &b)
  end
end

n = 50000
Benchmark.bm(7) do |x|
  x.report("1") { n.times do ; Elm.new([1,2],:map) ; end }
  x.report("2") { n.times do ; Enumerable::Enumerator.new([1,2],:map) ; end }
  x.report("3") { n.times do ; Elm.new(Enumerable::Enumerator.new([1,2],:map),:map) ; end }
end

