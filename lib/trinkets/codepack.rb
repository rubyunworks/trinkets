require 'facets/kernel/constant'

class Module

  # Divide code up into reusable *codepacks*.
  #
  #    module MyCodePacks
  #      codepack :foo do
  #        def foo
  #          "yes"
  #        end
  #      end
  #    end
  #
  #    class Y
  #      use MyCodePacks, :foo
  #    end
  #
  #    def test_codepack
  #      y = Y.new
  #      assert_equal( "yes", y.foo )
  #    end
  #
  def codepack(name, &block)
    @__codepack__ ||= {}
    return @__codepack__ unless block_given?
    @__codepack__[name.to_sym] = block
  end

  # Callback used by #use to insert codepacks.
  def provide_features(base, *selection)
    if selection.empty?
      @__codepack__.each do |k,codepack|
        base.class_eval( &codepack )
      end
    else
      selection.each do |s|
        base.class_eval( &@__codepack__[s.to_sym] )
      end
    end
  end

  # Use a codepack.
  def use(codepack, *selection)
    if String === codepack or Symbol === codepack
      codepack = constant(codepack)
    end
    codepack.provide_features( self, *selection )
  end

end


# --- test ---

if $0 == __FILE__

  require 'test/unit'

  class TCModule < Test::Unit::TestCase

    module MyPackages
      codepack :foo do
        def foo
          "yes"
        end
      end
    end

    class Y
      use MyPackages, :foo
    end

    def test_codepack
      y = Y.new
      assert_equal( "yes", y.foo )
    end

  end

end

