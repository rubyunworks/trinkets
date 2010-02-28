# TITLE:
#
#   Instance Intercept
#
# DESCRIPTION:
#
#   This code is in the spirit of class_extension, but performs method
#   instance level method interception instead of class level method inheritance.
#
# COPYRIGHT:
#
#   Copyright (c) 2005 Thomas Sawyer
#
# LICENSE:
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
# AUTHORS:
#
#   - Thomas Sawyer
#
# TODOS:
#
#   - WARNING! Highly expiremental code!
#
#   - Probably deprecate in favor of upcoming, better solutions.


#require 'facets/module/alias_method_chain'


# = Instance Interception
#
# This code is in the spirit of class_extension, but performs method
# instance level method interception instead of class level method inheritance.

class Module

  def instance_interception(&block)
    @instance_interception ||= Module.new do
      def self.append_features(mod)
        append_features_without_instance_interception( mod )
      end
    end
    @instance_interception.module_eval(&block) if block_given?
    @instance_interception
  end

  private :instance_interception

  alias_method :append_features_without_instance_interception, :append_features

  # Append features

  def append_features( mod )

    aspect = instance_interception
    aspect.__send__( :append_features_without_instance_interception, mod )

    aspect.instance_methods.each do |meth|
      if mod.method_defined?( meth )
        aspect.advise( mod, meth )
      end
    end

    append_features_without_instance_interception( mod )

    #if mod.instance_of? Module
    aspect.__send__( :append_features_without_instance_interception, mod.__send__(:instance_interception) )
    #end

  end

  # Apply the around advice.

  def advise( mod, meth )
    advice = instance_method( meth )
    instance_target = mod.instance_method(meth)
    mod.__send__( :define_method, meth ) { |*args| #, &blk|
      target = instance_target.bind( self )
      (class << target; self; end).class_eval { define_method( :super ){ call( *args ) } }
      advice.bind( self ).call( target, *args ) #, &blk )
    }
  end

  # TODO make method_added hook more robust so not as to clobber others.
  # If a method is added to the module/class that is advised.

  def method_added( meth )
    return if @method_added_short
    if instance_interception.method_defined?( meth )
      include instance_interception
      @method_added_short = true
      instance_interception.advise( self, meth )
      @method_added_short = false
    end
  end

end



=begin test

  require 'test/unit'

  class TestModule < Test::Unit::TestCase

    module A

      def f ; "F" ; end
      def g ; "G" ; end

      instance_interception do
        def f( target, *args, &blk )
          '{' + target.super + '}'
        end
        def g( target, *args, &blk )
          '{' + target.super + '}'
        end
      end

    end

    class X
      def f ; super ; end
      include A
      def g ; super ; end
    end

    def test_1_01
      x = X.new
      assert_equal( "{F}", x.f )
      assert_equal( "{G}", x.g )
    end

  end

=end
