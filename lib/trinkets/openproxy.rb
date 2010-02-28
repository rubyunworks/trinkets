
require 'nano/kernel/meta'


module Open
  def self.included( base )
    ( class << base ; self ; end ).class_eval {
      alias_method :create, :new
      define_method( :new ) { |*args|
        OpenProxy.new( base, *args )
      }
    }
  end
end


class OpenProxy

  EXCLUDE = /^(__|instance|null$|inspect$)/

  class << self
    #def new( delegate, *args, &blk )
    #  o = self.allocate
    #  self.initialize
    #  o.instance_eval { @self = delegate.create( *args, &blk ) }
    #  o
    #end

    def hide(name)
      if method_defined?(name) and name !~ EXCLUDE and name =~ /\w+/
        undef_method( name )
      end
    end
  end
  instance_methods.each { |m| hide(m) }

  # Proxy Methods

  def __self__ ; @self ; end

  #def inspect( *args, &blk )
  #  @self.inspect( *args, &blk )
  #end

  # Open Methods

  def initialize( base, init=nil, *args, &blk )
    @self = base.create( *args, &blk )
    @table = {}

    init ||= {}
    case init
    when Array
      @table = Hash[*init]
    when Hash
      @table = init.dup
    else
      @table = init.to_h.dup
    end
  end

  def method_missing( sym, *args )
    type = sym.to_s[-1,1]
    name = sym.to_s.gsub(/[=!?]$/, '').to_sym

    if type == '='
      @table[name] = args[0]
    elsif type == '!' and args.size > 0
      @table[name] = args[0]
      self
    else
      #if @table.key?(name)
        @table[name]
      #else
      #  Kernel.null #@table[name] = instance.class.new
      #end
    end
  end

  def to_a    ; @table.values ; end
  def to_h    ; @table.dup    ; end
  def to_hash ; @table.dup    ; end

  # duplicate
  def initialize_copy( orig )
    super
    @table = @table.dup
  end

  # Inspect the underlying delegate
  def inspect
    s = "<#{__meta__.class}"
    s << " " << @table.collect{|k,v| "#{k}=#{v.inspect}"}.join(' ') unless @table.empty?
    s << ">"
  end

  def marshal_dump
    @table
  end
  def marshal_load( tbl )
    @table = tbl
  end

  # Compare this object and +other+ for equality.
  def ==(other)
    return false unless other.__meta__.kind_of?( __meta__.class ) #other.__kind_of__?( __class__ )
    return @table == other.__table__
  end

  def [](name)
    name = name.to_sym
    #if @table.key?(name)
      @table[name]
    #else
    #  Kernel.null
    #end
  end

  def []=(name,val)
    @table[name.to_sym] = val
  end

  # For compatibility with other types of hash-like objects.
  # This may indicate a need for __each__ and a complete set
  # of secondary __#{name}__ methods from Enumerable.
  def each(&yld)
    @table.each( &yld )
  end

  # Some convenient shadow-methods (instead of doing '__meta__.foo')

  def __table__ ; @table ; end

  #def __get__(k) ; @table.key?(k.to_sym) ? @table[k.to_sym] : null ; end
  def __get__(k) ; @table[k.to_sym] ; end
  def __set__(k) ; @table[k.to_sym] = v ; end

  def __keys__ ; @table.keys ; end
  def __key__?(key) ; @table.key?(key) ; end

  def __update__( other )
    other = Hash[*other] if other.__meta__.is_a?(Array)
    other.each{ |k, v| @table[k] = v }
  end

  other.__meta__(:is_a?,Array)

  other.meta(:is_a?,Array)

  Meta[other].is_a?(Array)

  other.as(Hash).is_a?(Array)

  def __merge__( other )
    o = __meta__.dup
    o.__update__( other )
    o
  end

end



#  _____         _
# |_   _|__  ___| |_
#   | |/ _ \/ __| __|
#   | |  __/\__ \ |_
#   |_|\___||___/\__|
#

=begin testing

  require 'test/unit'

  class MyOpenObject
    include Open
  end

  class MyOpenObjectExtra
    include Open
    def x ; "x" ; end
    def u ; "u#{x}" ; end
  end

  class TC01 < Test::Unit::TestCase
    def setup
      @o =  MyOpenObjectExtra.new
    end

    def test_01_001
      assert_equal( "x", @o.__self__.x )
    end
    def test_01_002
      assert_equal( "ux", @o.__self__.u )
    end
    def test_01_003
      assert_equal( nil, @o.x )
    end
    def test_01_004
      assert_equal( nil, @o.u )
    end
  end

  class TC02 < Test::Unit::TestCase
    def test_02_001
      f0 = MyOpenObject.new
      f0[:a] = 1
      assert_equal( [1], f0.to_a )
      assert_equal( {:a=>1}, f0.to_h )
    end
    def test_02_002
      f0 = MyOpenObject.new( {:a=>1} )
      f0[:b] = 2
      assert_equal( {:a=>1,:b=>2}, f0.to_h )
    end
  end

  class TC03 < Test::Unit::TestCase
    def test_03_001
      f0 = MyOpenObject.new( :f0=>"f0" )
      h0 = { :h0=>"h0" }
      assert_equal( MyOpenObject.new( :f0=>"f0", :h0=>"h0" ), f0.__merge__( h0 ) )
      assert_equal( {:f0=>"f0", :h0=>"h0"}, h0.merge( f0 ) )
    end
    def test_03_002
      f1 = MyOpenObject.new( :f1=>"f1" )
      h1 = { :h1=>"h1" }
      f1.__update__( h1 )
      h1.update( f1 )
      assert_equal( MyOpenObject.new( :f1=>"f1", :h1=>"h1" ), f1 )
      assert_equal( {:f1=>"f1", :h1=>"h1"}, h1 )
    end
  end

  class TC04 < Test::Unit::TestCase
    def test_04_001
      fo = MyOpenObject.new
      10.times{ |i| fo.__send__( "n#{i}=", 1 ) }
      10.times{ |i|
        assert_equal( 1, fo.__send__( "n#{i}" ) )
      }
    end
  end

=end
