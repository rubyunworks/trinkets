# = TITLE:
#
#   RexmlBuilder
#
# = SUMMARY:
#
# Build XML Documents programatically with Ruby and REXML
# via the Builder Pattern --made possible by Ruby's blocks.
#
# = AUTHORS:
#
#   - 7rans
#
# = COPYRIGHT:
#
#   Copyright (c) 2006 Thomas Sawyer
#
# = LICENSE:
#
#   Ruby License
#
#   This module is free software. You may use, modify, and/or redistribute this
#   software under the same terms as Ruby.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#   FOR A PARTICULAR PURPOSE.

require 'rexml/document'
require 'facets/more/functor'

# = REXMLBuilder
#
# Build XML Documents programatically with Ruby and REXML
# via the Builder Pattern --made possible by Ruby's blocks.
#
# XmlBuilder uses REXML to contruct XML documents, helping to ensure
# XML specification conforamcy.
#
# == Usage
#
#   x = REXMLBuilder.new
#
#   favs = [ 'cake', 'jelly', 'salt' ]
#
#   x.table( :width=>'100%' ) {
#     x.tr {
#       favs.each { |v| x.td v }
#       }
#     }
#   }
#
# You can also setup the XmlBuilder to assume an implicit self,
# so the explict reciever is not needed.
#
#   x = REXMLBuilder.new( :implicit )
#
#   x.table( :width=>'100%' ) {
#     tr {
#         td "1" ; td "2" ; td "3"
#       }
#     }
#   }
#
# Implict building is more elegant in form, but it is not as
# functional because it makes it more difficult to refer to
# external values, ie. if 'favs' were used as in the previous
# example, it would be interpreted as another tag entry, not
# the array.

class REXMLBuilder

  # Privatize a few Kernel methods that are most likely to clash,
  # but arn't essential here. TODO Maybe more in this context?

  private :class, :clone, :display, :type, :method, :to_a, :to_s

  # Output XML document.

  def to_s( indent=nil )
    o = ""
    @target.write( o, indent || @options[:indent] || 0 )
    o
  end

  # raw insert

  def <<( str )
    r = builder.raw( str )
    if Array === r
      r.each { |e| @target << e }
    else
      @target << r
    end
    self
  end

  # Redirection functor.
  #--
  # TODO Better name?
  #++

  def out( str=nil )
    if str
      self << str
    else
      @builder_functor ||= Functor.new( &__method__(:+) )
    end
  end

  # text output

  def to_s
    @target.to_s
  end

private

  def builder
    REXMLUtil
  end

  # Prepare builder.

  def initialize( *options )
    # initialize options
    @options = (Hash === options.last ? options.pop : {} )
    options.each { |o| @options[o] = true }
    # initialize stack
    @stack = []
    # initialize buffer
    @target = builder.new( @options )
  end

  # Reroute -- Core functionality.

  def method_missing( tag, *args, &block )
    tag = tag.to_s
    if tag[-1,1] == '?'
      raise ArgumentError if block_given?
      out.instruct( tag.chomp('?'), *args )
    elsif tag[-1,1] == '!'
      out.declare( tag.chomp('!'), *args )
    else
      out.element( tag, *args )
    end
    if @current and block_given?
      @stack << @target
      @target = @current
      if @options[:implicit]
        instance_eval( &block )
      else
        block.call
      end
      @target = @stack.pop
    end
    @target
  end

  # Creates object via builder module,
  # stores as current and appends to buffer.

  def +( op, *args, &blk )
    obj = builder.send( op, *args, &blk )
    @current = obj
    @target << obj
    self
  end

end

# Module provides the build methods in
# an independent namespace.

module REXMLBuilder::REXMLUtil

  extend self

  # Add raw XML markup

  def raw( str )
    REXML::Document.new( "<root>#{str}</root>" ).root.to_a
  end

  # New REXML document.

  def document( options={} )
    #@options = options
    doc = REXML::Document.new
    # xml declaration
    if options[:version]
      doc << xml(
        options[:version],
        options[:encoding],
        options[:standalone]
      )
    end
    doc
  end

  # Used for initial taget in builder.
  alias_method :new, :document

  # XML declaration instruction.

  def xml( version=nil, *args )
    REXML::XMLDecl.new( version=nil, *args )
  end

  def element( tag, *args )
    keys = (Hash === args.last ? args.pop : {})
    skeys = {}
    keys.each { |k,v| skeys[k.to_s] =  v.to_s }
    e = REXML::Element.new( tag )
    e.add_attributes( skeys )
    e.add_text(args.join(' ')) unless args.empty?
    e
  end

  def instruct( name, *args )
    keys = (Hash === args.last ? args.pop : {})
    content = ( args + keys.collect{ |k,v| %{#{k}="#{v}"} } ).join(' ')
    REXML::Instruction.new( name, content.strip )
  end
  alias_method :instruction, :instruct
  alias_method :pi, :instruct

  def text( str, *args )
    REXML::Text.new( str, *args )
  end

  def comment( str, *args )
    REXML::Comment.new( str, *args )
  end

  def cdata( str, *args )
    REXML::CData.new( str, *args )
  end

  # DTD declarations

  def doctype!( *args )
    REXML::DocType.new( *args )
  end

  def element!( *args )
    REXML::ElementDecl.new( *args )
  end

  def attlist!( *args )
    REXML::AttlistDecl.new( *args )
  end

  def entity!( *args )
    REXML::EntityDecl.new( *args )
  end

  def notation!( *args )
    REXML::NotationDecl.new( *args )
  end

end



# TODO

=begin

x = REXMLBuilder.new( :version => '1.0' )

x.html {
  x.head { x.title "Test Document" }
  x.body( "try me" ){
    x.out.text "No more!"
    x.r? "x"
    x.img :src=>"smile.jp"
    x.h1 "Try Me"
    x.h2 "This is a test."
    x.div { x.span "Try" }
    x.out "<jump>one</jump>"
  }
}

puts x

=end
