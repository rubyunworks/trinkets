# = floatstring.rb
#
# == Copyright (c) 2004 Thomas Sawyer
#
#   Ruby License
#
#   This module is free software. You may use, modify, and/or redistribute this
#   software under the same terms as Ruby.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#   FOR A PARTICULAR PURPOSE.
#
# == Authors and Contributors
#
# * Thomas Sawyer
#
# == Developer Notes
#
#   TODO This library still needs work to be truly useful.

# Author::    Thomas Sawyer
# Copyright:: Copyright (c) 2004 Thomas Sawyer
# License::   Ruby License

# = FloatString
#
# FloatString is essentially a String but it allows unlimited
# string insertion between string segments.
#
# NOTE This library is still expiremental.

class FloatString

  def initialize( str )
    @str = str
    @float = {}
    i = 0
    while i < @str.length
      @float[i.to_f] = @str[i,1]
      i += 1
    end
  end

  def undo
    initialize( @str )
  end

  def re_enumerate
    initialize( to_s )
  end
  alias_method( :renumerate, :re_enumerate )

  def to_s
    @float.to_a.sort_by{ |k,v| k }.collect{ |k,v| v }.join('')
  end

  def to_str
    @float.to_a.sort_by{ |k,v| k }.collect{ |k,v| v }.join('')
  end

  # these should probably check the decimal and start there
  # rather then startint at 0.5

  def inner_insert(s, i)
    n = 0.5; i = i.to_f - n
    while @float.has_key?(i)
      n = n/2
      i += n
    end
    @float[i] = s
  end

  def outer_insert(s, i)
    n = 0.5; i = i.to_f - 0.5
    while @float.has_key?(i)
      n = n/2
      i -= n
    end
    @float[i] = s
  end

  def inner_append(s, i)
    n = 0.5; i = i.to_f + 0.5
    while @float.has_key?(i)
      n = n/2
      i -= n
    end
    @float[i] = s
  end

  def outer_append(s, i)
    n = 0.5; i = i.to_f + 0.5
    while @float.has_key?(i)
      n = n/2
      i += n
    end
    @float[i] = s
  end

  # an inner and outer wrap method would be nice

  def [](arg)
    if arg.kind_of?(Range)
      #r = Range.new(arg.first.to_f, arg.last.to_f, arg.exclude_end?)
      a = @float.to_a.sort_by{ |k,v| k }
      s = a.index(a.find{ |e| e[0] == arg.first.to_f})
      f = a.index(a.find{ |e| e[0] == arg.last.to_f})
      a = arg.exclude_end? ? a[s...f] : a[s..f]
      a.collect{ |k,v| v }.join('')
    else
      @float[arg.to_f]
    end
  end

  def []=(arg,v)
    @float[arg.to_f] = v
  end

  def fill(val, rng=0..-1)
    a = @float.to_a.sort_by{ |k,v| k }
    s = a.index( a.find{ |e| e[0] == rng.first.to_f } )
    f = a.index( a.find{ |e| e[0] == rng.last.to_f } )
    x = (rng.exclude_end? ? a[s...f] : a[s..f])
    x.each{ |k,v| @float[k] = val.to_s }
    self.to_s
  end

  def empty(rng)
    fill('', rng)
  end

  def blank(rng)
    fill(' ', rng)
  end

end



#  _____         _
# |_   _|__  ___| |_
#   | |/ _ \/ __| __|
#   | |  __/\__ \ |_
#   |_|\___||___/\__|
#

=begin test

  require 'test/unit' 

  class TC_FloatString < Test::Unit::TestCase

    def test_inner_inset
      fs = FloatString.new( "Hello World!" )
      fs.inner_insert("XXX", 4)
      assert_equal("HellXXXo World!", fs.to_s)
      fs.inner_insert("YYY", 4)
      assert_equal("HellXXXYYYo World!", fs.to_s)
    end

    def test_fill
      fs = FloatString.new( "Hello World!" )
      fs.inner_insert("XXX", 4)
      assert_equal("HeNNNN World!", fs.fill("N", 2..4))
    end

  end

=end
