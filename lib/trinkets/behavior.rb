# = Behavior
#
# Create temporary extensions.
#
# == Authors
#
# * Nobuyoshi Nakada
#
# == Todo
#
# * What was it? Something about selector namespaces...
#
# == Copyright
#
# Copyright (c) 2005 Nobuyoshi Nakada
#
# Ruby License
#
# This module is free software. You may use, modify, and/or redistribute this
# software under the same terms as Ruby.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.


# = Beahvior
#
# Behavior class is used to encapsulates a behavior.
#
#   nil.behaving(:to_nil) do
#     "1"
#   end
#
# TODO: This behavior library needs improvement. If we can
#       refine it enough and it proves solid, this would
#       make a good candidate for core.

class Behavior < Module
  #
  def define(behavior, &body)
    if body
      define_method(behavior, &body)
    else
      behavior.each do |behavior, body|
        if body
          define_method(behavior, &body)
        elsif body.nil?
          remove_method(behavior)
        else
          undef_method(behavior)
        end
      end
    end
  end
end

module Kernel

  def behaviors
    @_behaviors
  end

  #
  #
  #
  # CREDIT: Nobuyoshi Nakada

  def behaving(behavior, &body)
    unless @_behaviors
      extend(@_behaviors = Behavior.new)
    end
    @_behaviors.define(behavior, &body)
  end
end


# OLD IMPLEMENTATION

=begin
class Behavior < Module
    def initialize(behavior, &body)
    if body
      define_method(behavior, &body)
    else
      behavior.each do |behavior, body|
        if body
          define_method(behavior, &body)
        elsif body.nil?
          remove_method(behavior)
        else
          undef_method(behavior)
        end
      end
    end
  end
end

module Kernel
  def behaving(behavior, &body)
    extend(Behavior.new(behavior, &body))
  end
end
=end
