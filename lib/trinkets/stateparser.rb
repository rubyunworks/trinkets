# = stateparser.rb
#
# == Copyright (c) 2005 Thomas Sawyer
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
# == Author(s)
#
# * Thomas Sawyer

# Author::    Thomas Sawyer
# Copyright:: Copyright (c) 2005 Thomas Sawyer
# License::   Ruby License
# Date:: 2005-11-31

require 'ostruct'

# = StateParser
#
# Gerenal purpose stack-based parser. Define custom tokens
# and the parser will build a parse tree from them.
#
# StateParser is a stack-based parser with complete
# open access to the underlying parse machine. 
# You define tokens for it to find and what to 
# output when tokens are found. Event-triggers 
# allow for on-the-fly re-orientation of the machine.
# You can think of it as something like a Turing
#
# == Synopsis
#
# (note: these docs need updating)
#
# To use the parser you must define your token classes. There
# are three types of tokens: normal, raw and unit. Normal
# tokens are the default, requiring the definition of #start
# and #stop class methods. These must take a MatchData object
# as a parameter (although it need not be used) and return a regular
# expression to match against. Raw tokens are just like normal
# tokens except the parser will not tokenize what lies between the raw
# token's start and stop markers, instead reading it as raw text.
# Finally a unit token has no content, so a #stop method is not required,
# simply define the start #method to be used for matching.
#
#   require 'yaml'
#   require 'facets/more/stateparser'
#
#   s = "[p]THIS IS A [t][b]BOLD[b.]TEST[t.]&tm;[p.]"
#
#   class XmlTagToken < StateParser::Token
#     def self.start( match ) ; %r{ \[ (.*?) \] }mx ; end
#     def self.stop( match ) ; %r{ \[ [ ]* (#{esc(match[1])}) (.*?) \. \] }mx ; end
#   end
#
#   class XmlRawTagToken < StateParser::RawToken
#     def self.start( match ) ; %r{ \[ (t.*?) \] }mx ; end
#     def self.stop( match ) ; %r{ \[ [ ]* (#{esc(match[1])}) (.*?) \. \] }mx ; end
#   end
#
#   class XmlEntityToken < StateParser::UnitToken
#     def self.start( match ) ; %r{ \& (.*?) \; }x ; end
#   end
#
#   markers = []
#   markers << XmlRawTagToken
#   markers << XmlTagToken
#   markers << XmlEntityToken
#
#   cp = StateParser.new( *markers )
#   d = cp.parse( s )
#   y d
#
# _produces_
#
#   --- &id003 !ruby/array:Parser::Main
#   - &id002 !ruby/object:#<Class:0x403084a0>
#     body:
#       - "THIS IS A "
#       - &id001 !ruby/object:#<Class:0x403084a0>
#         body:
#           - !ruby/object:#<Class:0x403084a0>
#             body:
#               - BOLD
#             match: !ruby/object:MatchData {}
#             parent: *id001
#           - TEST
#         match: !ruby/object:MatchData {}
#         parent: *id002
#       - !ruby/object:#<Class:0x40308450>
#         body: []
#         match: !ruby/object:MatchData {}
#         parent: *id002
#     match: !ruby/object:MatchData {}
#     parent: *id003
#
# The order in which tokens are passed into the parser is significant,
# in that it decides token precedence on a first-is-highest basis.
#
# [Note: There are a few other subtilties to go over that I haven't yet
# documented, primarily related to creating more elaborate custom tokens. TODO!]
#
# Removed raw tokens. Raw text is now available to every regular
# token, so the end application can decided how to treat it.
#
# Removed priority. Order of tokens when parser is initialized
# now determines precedence.
#
# If first argument to Parser.new is not a kind of AbstractToken
# it is assumed to be the reentrant parser, otherwise the parser
# itself is considered the reentrant parser. Having this allows raw
# tokens to parse embedded content (among other things).

class StateParser ; end

module StateParser::Constants
  MATCH       = "match"
  ENDMATCH    = "end_match"
  CALLBACK    = "callback"
  ENDCALLBACK = "end_callback"
end

# StateMachine Class

class StateMachine
  class << self
    include ::StateParser::Constants

    def tokens ; @tokens ||= [] ; end
    def tokenIsUnit? ; @tokenIsUnit ||= {} ; end

    def token( name, &block )
      class_eval &block

      raise unless instance_methods.include?( MATCH )
      alias_method( "#{name}_#{MATCH}", :match )
      remove_method( MATCH )

      unit = !instance_methods.include?('end_match')
      tokenIsUnit?[name.to_sym] = unit
      unless unit
        alias_method( "#{name}_#{ENDMATCH}", ENDMATCH )
        remove_method( ENDMATCH )
      end

      if instance_methods.include?('callback')
        alias_method( "#{name}_#{CALLBACK}", CALLBACK )
        remove_method( CALLBACK )
      end

      if instance_methods.include?('end_callback')
        alias_method( "#{name}_#{ENDCALLBACK}", ENDCALLBACK )
        remove_method( ENDCALLBACK )
      end

      warn "WARNING! redefining token" if tokens.include?( name )
      tokens << name #Token.new( name, start_name, end_name )
    end

  end #class << self

  # instance methods -------------------------------------------------

  # token information
  def tokens ; self.class.tokens ; end
  def tokenIsUnit? ; self.class.tokenIsUnit? ; end

  # These you can fill out to do things on parser events.
  def flush( text, state ); end
  def finish( state ); end

end

# #
# #
# #
# class StateMachine::Token
#   attr_reader :name #:start, :stop
#   def initialize( name, start, stop )
#     @name = name
#     @start = start
#     @stop = stop
#   end
#   def start(machine,*args )
#     @start.bind(machine).call(*args)
#   end
#   def stop(machine,*args )
#     @stop.bind(machine).call(*args)
#   end
#   def unit?
#     @stop.nil?
#   end
# end

#
# Marker
#
# This is used to hold token places in the parse tree.
#
class StateParser::Marker
  attr_accessor :token, :begins, :ends, :info, :match
  attr_accessor :parent, :content, :outer_range, :inner_range
  def initialize
    @content = []
  end
  # array-like methods
  def <<( content ) ; @content << content ; end
  def last ; @content.empty? ? @content : @content.last ; end
  def empty? ; @content.empty? ; end
  def pop ; @content.pop ; end
  def each(&blk) ; @content.each(&blk) ; end
end

#
# State
#
class StateParser::State
  include ::StateParser::Constants

  attr_reader :text, :machine #, :info
  attr_reader :stack, :tkstack
  attr_accessor :offset, :mode

  def initialize( text, machine )
    @text = text.dup.freeze
    @machine = machine

    @offset = 0
    @stack = []
    @tkstack = []
    @current = {}
    @mode = nil
    #@info = OpenStruct.new
  end

  def next_start( token, index )
    re = machine.send( "#{token}_#{MATCH}", self )
    i = text.index( re, offset )
    if i
      m = $~
      e = m.end(0)
      if i < index # what comes first?
        @mode = machine.tokenIsUnit?[token] ? :UNIT : :START
        @current[:token] = token
        @current[:begins] = i
        @current[:ends] = e
        @current[:match] = m
        #@current[:info] = f
        return i
      end
    end
    return index
  end

  def next_end( index )
    token = @stack.last.token
    match = @stack.last.match
    re = machine.send( "#{token}_#{ENDMATCH}", match, self ) #machine.tokens[token].stop(match,self)
    i = text.index( re, offset )
    m = $~ if i
    e = m.end(0) if i
    if i and i < index # what comes first?
      @mode = :END
      @current[:token] = token
      @current[:begins] = i
      @current[:ends] = e
      @current[:match] = m
      #@current[:info] = f
      return i
    end
    return index
  end

  def clear_current
    @mode = nil
    @current = {}
  end

  def current_token  ; @current[:token]  ; end
  def current_begins ; @current[:begins] ; end
  def current_ends   ; @current[:ends]   ; end
  def current_match  ; @current[:match]  ; end
  def current_info   ; @current[:info]   ; end

  def mock( current )
    mock = StateParser::Marker.new
    mock.token = current_token
    mock.begins = current_begins
    mock.ends = current_ends
    mock.match = current_match
    mock.info = current_info
    mock.parent = current
    mock
  end

  # increment the offset
  def next_offset
    @offset = current_ends
  end

  def trigger
    machine.send("#{current_token}_#{CALLBACK}", current_match, self)
  end

  def end_trigger
    machine.send("#{current_token}_#{ENDCALLBACK}", current_match, self)
  end

  def trigger_flush( text )
    machine.send("flush", text, self) #if machine.respond_to?(:flush)
  end

  def trigger_finish
    machine.send("finish", self) #if machine.respond_to?(:finish)
  end

  #def to_s
  #  @stack.join
  #end
end


#
#
#
class StateParser

  attr_reader :machine

  def initialize( machine )
    @machine = machine
  end

  def parse( text )
    stack = reparse( text )
    return stack
  end

  private

  def reparse( text )

    state = State.new( text, @machine )
    root = Marker.new #state.stack
    current = root
    finished = nil

    until finished
      state.clear_current
      index = text.length  # by comparision to find the nearest match

      unless state.tkstack.empty? #state.stack.empty?
        raise "not a marker on end of stack?" unless Marker === state.stack.last  # should not happen
        index = state.next_end( index )
      end

      machine.tokens.each do |tokn|
        index = state.next_start( tokn, index )
        # NOTE not making sure there is a matching end token.
        # bad or good idea? the code might go here if need be
        # but the parser is faster without it.
      end

#       # finished is +nil+ if were just getting started
#       # +false+ while running and then +true+ when done.
#       unless state.stack.last
#         finished = ( finished.nil? ? false : true )
#         state.mode = :FINISH if finished
#       end

      case state.mode
      when :START
        buffer_text = state.text[state.offset...index]
        current << buffer_text unless buffer_text.empty?

        # signal flush
        state.trigger_flush( buffer_text )

        # adjust current
        mock = state.mock( current )
        current << mock
        current = mock
        state.stack << mock

        # add token to token stack
        state.tkstack << current.token if current.token

        state.next_offset

        # signal start trigger
        state.trigger

      when :END
        buffer_text = state.text[state.offset...index].chomp("\n")
        current << buffer_text unless buffer_text.empty?

        # signal flush
        state.trigger_flush( buffer_text )

        # adjust current
        mock = state.stack.pop
        mock.outer_range = mock.begins...state.current_ends
        mock.inner_range = mock.ends...state.current_begins
        current = mock.parent

        # remove token from token stack
        state.tkstack.pop

        state.next_offset

        # signal ending trigger
        state.end_trigger

      when :UNIT
        buffer_text = state.text[state.offset...index] #.chomp("\n")
        current << buffer_text unless buffer_text.empty?

        # signal flush
        state.trigger_flush( buffer_text )

        # adjust current
        mock = state.mock( current )

        mock.outer_range = state.current_begins...state.current_ends
        current << mock

        #state.tkstack << current.token

        state.next_offset

        # signal start trigger
        state.trigger

      else
        buffer_text = state.text[state.offset..-1].chomp("\n")
        current << buffer_text unless buffer_text.empty?

        # signal flush
        state.trigger_flush( buffer_text )

        # signal finish
        state.trigger_finish

        # wrap it up
        finished = true

      end #case state.mode

    end #until finished

    return root
  end

end #class Parser



# #
# # Token Definition Class
# #
# class StateParser::Token
# 
#   attr_reader :key #, :type
# 
#   def initialize( key )
#     @key = key
#   end
# 
#   def unit? ; false  ; end
#   #def raw? ; @type == :raw ; end
#   #def normal? ; @type != :raw && @type != :unit ; end
# 
#   def start( text, offset, state )
#     raise "start undefined for #{key}"
#   end
# 
#   #def stop( match=nil )
#   #  raise "stop undefined for #{key}" unless @stop
#   #  @stop.call( match )
#   #end
# 
# end

# #
# # Unit Token Definition Class
# #
# class StateParser::UnitToken
# 
#   attr_reader :key #, :type
# 
#   def initialize( key )
#     @key = key
#   end
#
#   def unit? ; true  ; end
#   #def raw? ; @type == :raw ; end
#   #def normal? ; @type != :raw && @type != :unit ; end
#
#   def start( text, offset, state )
#     raise "start undefined for #{key}"
#   end
#
# end



#  _____         _
# |_   _|__  ___| |_
#   | |/ _ \/ __| __|
#   | |  __/\__ \ |_
#   |_|\___||___/\__|
#

# TODO

=begin #test

  require 'yaml'
  require 'facets/core/string/regesc'

  s = %Q{MON[p]This is plain paragraph.[t][b]This bold.[b.]This tee'd off.[t.]&tm;[p.]KEY&tm;}

  class MyMachine < StateMachine

    attr_accessor :tag_stack

    def initialize
      @tag_stack = []
    end

    token :tag do

      def match( state )
        %r{ \[ (.*?) \] }mx
      end

      def end_match(match, state)
        %r{ \[ [ ]* (#{tag_stack.last.regesc}) (.*?) \. \] }mx
      end

      def callback( match, state )
        tag_stack << match[1]
        puts "<#{match[1]}>"
      end

      def end_callback( match, state )
        t = tag_stack.pop
        puts "</#{match[1]}>"
      end

    end

    token :entity do

      def match( state )
        %r{ \& (.*?) \; }x
      end

      def callback( match, state )
        puts "&" + match[1] + ';'
      end

    end

  end

  cp = StateParser.new( MyMachine.new )
  d = cp.parse( s )
  y d

=end
