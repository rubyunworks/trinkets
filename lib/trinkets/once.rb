# = once.rb
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
# == Author(s)
#
# * Thomas Sawyer

# Author::    Thomas Sawyer
# Copyright:: Copyright (c) 2006 Thomas Sawyer
# License::   Ruby License

# = Once
#
# Once is a memoize/cache functor.
#
# == Usage
#
#   class X
#     def initialize ; @tick = 0 ; end
#     def tick; @tick + 1; end
#     def once; Once.new( self ) ; end
#   end
#
#   x = X.new
#   x.tick  #=> 1
#   x.once.tick  #=> 2
#   x.tick  #=> 3
#   x.once.tick  #=> 2
#   x.tick  #=> 4
#   x.once.tick  #=> 2

class Once

  # Privatize a few Kernel methods that are most likely to clash,
  # but arn't essential here.

  private :class, :clone, :display, :type, :method, :to_a, :to_s

  def initialize( target )
    @self = target
    @cache = {}
  end

  def self ; @self ; end

  def method_missing( meth, *args, &blk )
    return @cache[ [meth,*args] ] if @cache.key?( [meth, *args] )
    @cache[ [meth,*args] ] = @self.send( meth, *args, &blk )
  end

end
