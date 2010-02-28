# = Exception-based Event Hooks
#
# Provides an Event Hooks system designed
# on top of Ruby's built-in Exception system.
#
#   def dothis2
#     puts 'pre'
#     hook :quitit
#     puts 'post'
#   end
#
#   def tryit2
#     begin
#       puts "BEFORE"
#       dothis2
#       puts "AFTER"
#     rescue EventHook
#       event :quitit do
#         puts "HERE"
#       end
#     end
#   end
#
#   tryit2
#
# produces
#
#   BEFORE
#   pre
#   HERE
#   post
#   AFTER
#
# Note that EventHook use callcc.
#
#--
# TODO: Can't use callcc in Ruby 1.9? If so then this will
# need a new implementation, perhaps using Fibers. Otherwise
# it will have to be deprecated.
#++

class EventHook < Exception
  attr_reader :name, :cc
  def initialize(name, cc)
    @name = name
    @cc = cc
  end
  def call
    @cc.call
  end
end

module Kernel
  def hook(sym)
    callcc{ |c| raise EventHook.new(sym, c) }
  end
  def event(sym)
    if $!.name == sym
      yield
      $!.call
    end
  end
end


# --- test ---

if $0 == __FILE__

  require 'test/unit'

  class TestEventHook < Test::Unit::TestCase

    class T
      attr_reader :a
      def dothis
        @a << '{'
        hook :here
        @a << '}'
      end
      def tryit
        @a = ''
        begin
          @a << "["
          dothis
          @a << "]"
        rescue EventHook
          event :here do
            @a << "HERE"
          end
        end
      end
    end

    def test_run
      t = T.new
      t.tryit
      assert_equal('[{HERE}]', t.a)
    end

  end

end

