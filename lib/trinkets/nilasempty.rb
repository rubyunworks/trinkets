# NilClass as Emptiness or Nothingness.
#
# The ideas here is to have nil act more like
# an empty set than an error catcher.
# So you get responses like
#
#   nil.include?(:x) # => nil
#
# instead of an error being raised.
#
# WARNING! One should be aware that in some rare cases
# incompatabilites may arise when using these methods in
# conjuction with other libraries.


class NilClass

  # Allows <tt>nil</tt> to respond to #to_f.
  # Always returns <tt>0</tt>.
  #
  #  nil.size   #=> 0
  #
  def to_f; 0.0; end

  # Allows <tt>nil</tt> to create an empty hash,
  # similar to #to_a and #to_s.
  #
  #  nil.to_h    #=> {}
  #
  def to_h; {}; end

  # Allows <tt>nil</tt> to respond to #size.
  # Always returns <tt>0</tt>.
  #
  #  nil.size   #=> 0
  #
  def size; 0; end

  # Allows <tt>nil</tt> to respond to #length.
  # Always returns <tt>0</tt>.
  #
  #  nil.length   #=> 0
  #
  def length; 0; end

  # Allows <tt>nil</tt> to respond to #blank? method.
  # Alwasy returns <tt>true</tt>.
  #
  #  nil.blank?   #=> true
  #
  def blank? ; true ; end

  # Allows <tt>nil</tt> to respond to #empty? method.
  # Alwasy returns <tt>true</tt>.
  #
  #  nil.empty?   #=> true
  #
  def empty? ; true ; end

  # Allows <tt>nil</tt> to respond to #[].
  # Always returns nil.
  #
  #  nil[]   #=> nil
  #
  def [](*args)
    nil
  end

  # Allows <tt>nil</tt> to respond to #include? method.
  # Alwasy returns <tt>nil</tt>.
  #
  #  nil.include?("abc")   #=> nil
  #
  def include?(*args); nil; end

end




#  _____         _
# |_   _|__  ___| |_
#   | |/ _ \/ __| __|
#   | |  __/\__ \ |_
#   |_|\___||___/\__|
#
=begin test

  require 'test/unit'

  class TestNilClass < Test::Unit::TestCase

    def test_to_h
      assert_equal( {}, nil.to_h )
    end

    def test_length
      assert_equal( 0, nil.length )
    end

    def test_size
      assert_equal( 0, nil.size )
    end

    def test_blank?
      assert( nil.blank? )
    end

    def test_empty?
      assert( nil.empty? )
    end

    def test_op_fetch
      assert_equal( nil, nil[] )
      assert_equal( nil, nil[1] )
      assert_equal( nil, nil[1,2,3] )
    end

    def test_include?
      assert_equal( nil, nil.include? )
    end

  end

=end
