require 'test/unit'
require 'closecall'

#class Object
#  include CloseCall
#end

class TC_CloseCall < Test::Unit::TestCase

  # fixture
  class T
    include CloseCall

    def someMethod(arg1)
      return "1:#{arg1}"
    end

    def someMethod2(arg1)
      return "2:#{arg1}"
    end

    def someMethod3(arg1, arg2)
      return "3:#{arg1},#{arg2}"
    end
  end

  def test_it
    test = T.new
    assert_equal( '3:a,b', test.somemethod('a', 'b') )
    assert_equal( '1:a', test.somemethod('a') )
    assert_equal( '2:b', test.somemethod2('b') )
    assert_raises( NameError, test.somemethod('a', 'b', 'c') )
  end
 
end
