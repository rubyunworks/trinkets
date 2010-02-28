
require 'nano/unboundmethod/name'
require 'nano/enumerable/uniq_by'
require 'nano/hash/keys_to_sym'

class NoServiceError < NoMethodError ; end

# In general the term 'service' is just another name for method
# (in Ruby also an attribute). Here it takes on slightly more meaning
# in that it is a managed first class object.
#
class Service

  def initialize( klass, name, allow_virtual=false )
    unless allow_virtual
      raise NoServiceError, "#{klass} service ##{name} does not exist" unless klass.method_defined?(name)
    end
    @name = name.to_s
    @class = klass
    @bindings={}
    service
  end

  def name ; @name ; end
  def for_class ; @class ; end

  def service
    if @class.instance_methods(false).include?(@name)
      @method = @class.instance_method(@name)
    else
      if @class.method_defined?(@name)
        @class.instance_method(@name)
      end
    end
  end

  def virtual?
    service ? false : true
  end

  #--
  # do about virtual here ?
  #++
  def super_service?
    # recall method_defined looks at all ancestors too
    @class.ancestors[1] and @class.ancestors[1].method_defined?(name.to_sym)
  end

  def super_service
    super_service? ? @class.ancestors[1].service(name) : nil
  end

  def service_ancestors
    return [@class] unless super_service?
    [@class].concat super_service.service_ancestors
  end

# TODO
  #def hash
  #
  #end

  #def ===(other)
  #  @name == other.name and @class.ancestors.include?(other.for_class)
  #end

  def inspect
    if virtual?
      %{#<Virtual#{self.class}:#{@class}##{@name}>}
    else
      if @class.instance_methods(false).include?(@name)
        %{#<#{self.class}:#{@class}##{@name}>}
      else
        %{#<#{self.class}:#{@class}(#{service_ancestors.slice(1..-1).join(',')})##{@name}>}
      end
    end
  end

  def <=>(other)
    return c = @name <=> other.name if c != 0
    return c = @class <=> other.for_class if c != 0
    0
  end

  # Returns metadata merged with ancestor's metadata.
  def super_metadata
    return super_service.super_metadata.merge(metadata) if super_service?
    return metadata
  end
  alias :open_metadata :super_metadata

  # This is here to ensure open_metadata works
  # even when nano/object/metadata isn't loaded.
  def metadata
    @_metadata ||= {}
  end

  # Bind service to an instance of it's for-class.
  def bind(obj)
    raise 'virtual service has no target method' if virtual?
    @bindings[obj] ||= @method.bind(obj)
  end

  # Unbind service to an instance of it's for-class.
  def unbind(obj)
    @bindings.delete(obj).unbind if @bindings.include?(obj)
  end

  # Returns arity of service.
  def arity
    return nil if virtual?
    @method.arity
  end

  # Call services on all bound instances.
  def call(*args,&blk)
    raise 'virtual service has no target method' if virtual?
    @bindings.each{|b| b.call(*args,&blk)}
  end

  # Call the service's (method's) super service (method).
  def super_call(*args,&blk)
    super_service.call(*args,&blk) if super_service?
  end

end


class Object
  def service(name)
    self.class.service(name)
  end
  def has_service?(name)
    self.class.method_defined?(name)
  end
end


class Module

  # Returns the hash of local _instantiated_ services.
  def __service__
    @__service__ ||= Hash.new{ |h,k| h[k.to_sym]=Service.new( self, k, true ) }
    @__service__
  end

  # Returns a service by name.
  def service( name )
    raise NoServiceError unless has_service?(name) unless virtual_service?(name)
    __service__[name.to_sym]
  end

  # Returns a service by name, if doesn't exist creates it.
  def virtual_service(name)
    __service__[name.to_sym]
  end

  # Returns a list of names of the currently instantiated services.
  def services
    __service__.keys | ( ancestors[1] ? ancestors[1].services : [] )
  end
  alias :open_services :services

  def virtual_services
    a = []
    __service__.each{ |k,s| a << k if s.virtual? } #unless ancestors[1]
    a
  end

  # This will instantiate all possible services.
  # This is an expensive operation, use sparingly.
  def all_services(include_ancestors=false)
    instance_methods(include_ancestors).collect{ |m| service(m) }
  end

  # Does this module/class have a service?
  def service?(name)
    method_defined?(name)
  end
  alias :has_service? :service?

  # Does this module/class have a virtual service?
  def virtual_service?(name)
    virtual_services.include?(name)
  end
  alias :has_virtual_service? :virtual_service?

  # Simply a wrapper around instance_methods, but converts to symbols
  def services_available(include_ancestors=true)
    instance_methods(include_ancestors).collect{ |m| m.to_sym }
  end

end



#  _____         _
# |_   _|__  ___| |_
#   | |/ _ \/ __| __|
#   | |  __/\__ \ |_
#   |_|\___||___/\__|
#

=begin testing

  require 'mega/quicktest'

  class X
    def name; "X.name" ; end
    def bang; "X.bang" ; end
  end

  class Y < X
    def name; "Y.name" ; end
    def jump; "Y.jump" ; end
  end

  #test { assert_equal( X.instance_methods(true), X.services ) }
  #test { assert_equal( Y.instance_methods(true), Y.services ) }
  #test { assert_equal( ["jump"], Y.services - X.services ) }

  test do
    X.service(:name)
    assert_equal( [:name], X.services )
    assert_equal( [:name], Y.services )
  end

  test do
    Y.service(:name)
    assert_equal( [:name], X.services )
    assert_equal( [:name], Y.services )
  end

  test do
    assert( Y.service(:name).super_service? )
  end

  test do
    Y.service(:jump)
    assert_equal( [:name], X.services )
    assert( [:name,:jump].each { |s| Y.services.include?(s) } )
  end

  test do
    assert( ! Y.service(:jump).super_service? )
  end

  test do
    Y.service(:bang)
    assert( [:name,:bang].each { |s| X.services.include?(s) } )
    assert( [:name,:jump,:bang].each { |s| Y.services.include?(s) } )
  end

  test do
    assert_raises( NoServiceError ){ Y.service(:noop) }
  end

  test do
    Y.virtual_service(:noop)
    assert_equal( [:noop], Y.virtual_services )
    assert( [:name,:jump,:bang,:noop].each { |s| Y.services.include?(s) } )
    assert( Y.service(:noop).virtual? )
    assert( ! Y.service(:jump).virtual? )
  end

=end
