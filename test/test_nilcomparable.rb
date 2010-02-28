require 'test/unit'
require 'nilcomparable'

class Mock < String
  alias_method :compare_without_nil, :<=>
  def <=>( other )
    return 1 if other.nil?
    compare_without_nil( other )
  end
end

class TestNilClassComparable < Test::Unit::TestCase

  def test001
    assert_equal( 0, nil <=> nil )
    assert_equal( -1, nil <=> 4 )
    assert_equal( -1, nil <=> "a" )
    assert_equal( -1, nil <=> Object.new )
    assert_equal( 0, nil.cmp(nil) )
    assert( nil < 4 )
  end

  def test002
    m = Mock.new("A")
    assert_equal( 1, m <=> nil )
    assert_equal( -1, m <=> "B" )
    #assert_equal( 1, m.cmp(nil) )
    assert( m > nil )
  end

end

