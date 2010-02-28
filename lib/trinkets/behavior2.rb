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

class Behaviors < Module
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
  # CREDIT: Trans
  # CREDIT: Nobuyoshi Nakada

  def behaving(*behavior_modules, &block)
    @_behaviors = Module.new unless @_behaviors

    @_behaviors.__send__(:include, *behavior_modules.reverse)

    extend(@_behaviors)  # reinforce for module inclusion problem (right?)

    behavior_modules.each do |behavior|
      behavior.instance_methods.each do |m|
        @_behaviors.__send__(:define_method, m){ super }
      end
    end

    begin
      instance_eval(&block)
    ensure
     behavior_modules.each do |behavior|
        behavior.instance_methods.each do |m|
          @_behaviors.__send__(:undef_method, m)
        end
      end
    end
  end

end


module MyStringBehaviors # < Behaviors

  def x
    self + "-okay"
  end

end

a = "this is a test"

a.behaving(MyStringBehaviors) do
  puts x
end

begin
  puts a.x
rescue
  puts "here"
end

a.behaving(MyStringBehaviors) do
  puts x
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

