require 'enumerator'

class Enumerable::Enumerator

  # Adds immediate element-wise ability to Enumerator.
  # Any non-enumeration method is passed on to each.
  #
  #   [1,2,3].to_enum(:map) + 3
  #   => [4,5,6]
  #
  # As of Ruby 1.9+ you will be able to use the more
  # concise notation:
  #
  #   ([1,2,3].map + 3).to_a
  #
  # Enumerator methods can't be used with this.
  # In those cases use #apply.

  def method_missing(sym,*args,&blk)
    each{ |x| x.send(sym,*args,&blk) }
  end

end


class Enumerable::ContinuousEnumerator < Enumerable::Enumerator

  def method_missing(sym,*args,&blk)
    self.class.new(each{ |x| x.send(sym,*args,&blk) })
  end

end


module Enumerable
  def to_enumc(meth)
    ContinuousEnumerator.new(self, meth)
  end
end
