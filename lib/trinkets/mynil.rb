
# mynil

class Hash
  alias :+ merge
end

class NilClass

  undef_method :to_s, :to_f, :to_i, :to_a

  AsDefault = { :to_s=>'', :to_f=>0.0, :to_i=>0, :to_a=>[] }
  AsEmpty = AsDefault + {:to_h=>{}}
  AsZero = {:to_i=>0, :to_f=>0.0}
  AsNothing = AsEmpty + AsZero
  AsSelf = lambda { nil }
  AsNil = lambda { nil }
  AsError = {}

  def as(role, &block)
    role = NilClass::const_get(role) if String === role or Symbol === role
    if block
      @role_restore ||= []
      @role_restore.push @role
      @role = role
      yield
      @role = @role_restore.pop || {}
    else
      @role = role
    end
  end

  def end_as
    @roll = @role_restore
  end

  def method_missing( m, *a, &b )
    @role ||= {}
    if @role[m]
      r = @role[m]
      Proc === r ? r.call(*a,&b) : r
    else
      super
    end
  end

  nil.as(AsDefault)
end

# Try it.

p nil.to_i

nil.as(:AsEmpty) do
  p nil.to_h
end

nil.as(:to_s=>"No answer") do
  p nil.to_s
  p nil.to_h # assert: raises NoMethodError
end


