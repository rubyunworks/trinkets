

class Function

  #
  #    MODES    block   Proc.new    ?     lambda
  #           +----------------------------------
  #   @pcheck | false    true     false    true
  #   @rlocal | false    false    true     true
  #
  def initialize( name=nil, pcheck=false, rlocal=false, &func )
    @func = func
    @name = name
    @rlocal = rlocal  # return_local
    @pcheck = pcheck  # check_parameters

    @inst = false
    @bind = nil
  end

protected

  #def func=(n)  ; @func = n  ; end  # really need ?
  #def name=(n)  ; @name = n  ; end

public

  def name      ; @name   ; end
  def binding   ; @bind   ; end
  def instance? ; @inst   ; end
  def local?    ; @rlocal ; end
  def check?    ; @pcheck ; end

  # control the parameter checking mode

  def check
    @pcheck = true
    self
  end

  def nocheck
    @pcheck = false
    self
  end

  # control the local return mode

  def local
    @rlocal = true
    self
  end

  def nonlocal
    @rlocal = false
    self
  end

  #def with_mode( pcheck, rlocal=@rlocal )
  #  @pcheck = pcheck
  #  @rlocal = rlocal
  #  self
  #end

  def bind( obj, name=@name )
    raise 'method must have a name' unless name
    raise 'method must have an object to bind to' unless obj
    obj.class.send( :define_method, name, &@func )
    @bind = obj
    @inst = true
    @__m__ = obj.method( name )
    self
  end

  def unbind
    @bind = @bind.class
    @inst = false
    @__m__ = @__m__.unbind
    self
  end

  def define( mod, name=@name )
    raise 'unbound method must have a name' unless name
    raise 'unbound method must have an a module/class to be defined within' unless klass
    klass.send( :define_method, name, &func )
    @bind = klass
    @inst = false
    @__m__ = klass.instance_method( name )
    self
  end

  def undefine
    @bind = nil
    @inst = false
    @__m__ = nil
    @bind.remove_method( @name )
    self
  end

  # usage methods

  def call(*args, &blk)
    if @pcheck && @func.arity > -1
      raise ArgumentError, "wrong number of arguments ( #{args.size} for #{@func.arity} )" if @func.arity != args.size
    end
    if @bind and @inst       # method
      @__m__.call(*args, &blk)
    elsif @bind and ! @inst  # unbound method
      call_func(*args, &blk)
    else
      call_func(*args, &blk)
    end
  end

  def call_func(*args, &blk)
    if @rlocal
      lambda(&@func).call(*args, &blk)
    else
      @func.call(*args, &blk)
    end
  end
  private :call_func

  alias_method :[], :call

  def arity
    @func.arity
  end

  # -- LEGACY TERMS -------------------

  def as_block!  ; self.nocheck.nonlocal ; end
  def as_block   ; self.dup.as_block!    ; end

  def as_lambda! ; self.check.local      ; end
  def as_lambda  ; self.dup.as_lambda!   ; end

  def as_proc!   ; self.check.nonlocal   ; end
  def as_proc    ; self.dup.as_proc!     ; end

  def to_lambda
    lambda(&@func)
  end

  def to_proc
    Proc.new(&@func)
  end

  def to_umethod( mod, name=@name )
    raise 'unbound method must have a name' unless name
    raise 'unbound method must have an asscoitated to a class or module' unless mod
    self.define( mod, name )
    return mod.instance_method( name )
  end
  alias_method :to_unboundmethod, :to_umethod

  def to_method( obj, name=@name)
    raise 'method must have a name' unless name
    raise 'method must have an asscoitated ibject binding' unless obj
    self.bind( obj, name )
    return obj.method( name )
  end

end


# test

if $0 == __FILE__

  require 'test/unit'

  # fixture

  class C
    def nonlocal_return
      Function.new{ return 'Y' }.nonlocal.call ; 'N'
    end
    def local_return
      Function.new{ return 'Y' }.local.call ; 'N'
    end
    def check_params
      Function.new{ |a,b| [a,b] }.check
    end
    def nocheck_params
      Function.new{ |a,b| [a,b] }.nocheck
    end
  end

  # testcase

  class TC_Function < Test::Unit::TestCase

    def setup
      @c = C.new
    end

    def test_returning
      assert_equal( "Y", @c.nonlocal_return )
      assert_equal( "N", @c.local_return )
    end

    def test_checkng
      assert_equal( [1,2], @c.check_params.call(1,2) )
      assert_raises( ArgumentError ) { @c.check_params.call(1) }
      assert_equal( [1,nil], @c.nocheck_params.call(1) )
    end

  end

end

  f = Function.new { |x,y| x+y }

  # test call

  print f[1,2] ; puts "  [3]"


  # test binding

  class K ; end
  k = K.new

  print k.respond_to?(:add) ; puts "  [false]"

  f.bind(k, :add)

  print k.respond_to?(:add) ; puts "  [true]"
  print k.add(1,2) ; puts "  [3]"

  f.unbind

  print k.respond_to?(:add) ; puts "  [false]"


=begin
  class D

    def initialize( &blk )
      @blk = blk
    end

    def lambda_return
      lambda { return 'Y' }.call ; 'N'
    end

    def proc_return
      Proc.new { return 'Y' }.call ; 'N'
    end

    def lambda_return_blk
      lambda(&@blk).call ; 'N'
    end

    def proc_return_blk
      @blk.call ; 'N'
    end

  end

  class C
    def lambda_return_blk
      D.new { return 'Y' }.lambda_return_blk
    end
    def proc_return_blk
      D.new { return 'Y' }.proc_return_blk
    end
  end

  c = C.new

  #p d.lambda_return #=> 'N'
  #p d.proc_return   #=> 'Y"

  p c.lambda_return_blk #=> 'N'
  p c.proc_return_blk   #=> 'Y"

=end
