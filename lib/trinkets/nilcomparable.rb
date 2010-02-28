# Author::    Thomas Sawyer, Paul Brannan
# Copyright:: Copyright (c) 2005 Thomas Sawyer, Paul Brannan
# License::   LGPL v3

# This tiny framework simply makes nil comparable, such that
# all things (except itself) are greater than it.
#
# The main effect is this:
#
#   nil <=> any_object   #=> -1
#
# To enable a class to compare against nil (reverse of the above),
# simply prepend a nil comparsion into the #<=> method of that class.
# For example:
#
#   class Foo
#     def initialize( value )
#       @value = value
#     end
#
#     def <=>( other )
#       return 1 if other.nil?  # nil comparison
#       @value <=> other
#     end
#
#   end
#
# To do so for a pre-existing class with a pre-existing #<=> method, you'll 
# need to overide the method. As an example let's make Numeric comparable to nil.
#
#   class Numeric
#     alias_method :compare_without_nil, :<=>
#     def <=>( other )
#       return 1 if other.nil?
#       compare_without_nil( other )
#     end
#   end
#
# Or more conveniently:
#
#   require 'facets/module/wrap_method'
#
#   Numeric.wrap_method(:<=>) do |prev, other|
#     return 1 if other.nil?
#     prev.call(other)
#   end
#
# NilCompariable is a mixin module that can do the above automatically.
# The including class should have #<=> defined, then simple include the
# mixin.
#
#   class Numeric
#     include NilComparable
#   end
#
# == Important Consideration
#
# Changing this behavior for of NilClass to be comparable is not something
# to be done lightly. Potentially it could cause unexpected errors in 
# other's code. So it is best to use this library only when you have full
# control of the code being executed.
#
# == Acknowledgements
#
# NilComparable is based on the library from Paul Brannan's Ruby Treasures.

module NilComparable
  def self.included(mod)
    mod.class_eval %{
      if method_defined?( :<=> )
        alias_method :compare_without_nil, :<=>
      else
        def compare_without_nil( other )
          raise TypeError, "Cannot compare \#{self.inspect} to \#{other.inspect}"
        end
      end

      def <=>(other)
        return 1 if other.nil?
        compare_without_nil(other)
      end
    }
  end
end

class NilClass #:nodoc:
  include Comparable

  # Any comparison against nil with return -1,
  # except for nil itself which returns 0.

  def <=>(other)
    other.nil? ? 0 : -1
  end

  alias_method( :cmp, :<=> )

  def succ(n=nil); nil; end
end

