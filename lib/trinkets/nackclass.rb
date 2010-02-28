# = NackClass
#
# Not Acknowledged. An alternative to NilClass is cases where
# nil is a valid option, but a non-option still needs to
# be recognized.
#
class NackClass < Exception  #NilClass
  def inspect; "nack"; end
  class << self
    private :new
  end
end

NACK = NackClass.instance_eval{ new }

module Kernel
  # This is a light version of NackClass intended
  # for minor usecases. See mega/nack for a complete version.
  #
  def nack
    NACK
  end
end

