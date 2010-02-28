# Test lib/more/ext/facets/let.rb

require 'facets/kernel/let'
require 'test/unit'

class TestKernelLet < Test::Unit::TestCase

  class Foo
    let.bar = 10
  end

  def test01
    x = Foo.new
    assert_equal( 10, x.bar )
  end

end

