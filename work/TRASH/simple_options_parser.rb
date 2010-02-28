# (c) Jan Molic
# licence: Ruby's

class SimpleOptionsParser

	class Option

		attr_accessor :id, :value

		def initialize( parent, id )
			@parent = parent
			@id = id
			@value = nil
			if @parent.map[ @id ][2] == :required
				@value = @parent.argv.shift
			end
		end

		def has_optional_value?()
			@parent.map[ @id ][2] == :optional
		end

	end # class Option

	attr_reader :options, :arguments, :unknown_options, :all, :map, :argv

	def initialize( argv, map )
		@map = map
		@argv = argv
		@options = [] # contains options
		@arguments = [] # contains arguments
		@all = [] # contains both options and arguments if someone needs exact order of them
		@unknown_options = [] # contains names of options which aren't defined in the map
		last_opt = nil
		while arg = @argv.shift
			# parses "-a" or more at once "-abcd"
			if arg.match( /^-([^-].*)$/ )
				$1.split( '' ).each { |optname|
					if opt = get_id( optname )
						last_opt = opt
						@options << last_opt
						@all << last_opt
					end
				}
			# parses "--foo" or "--foo=BAR"
			elsif arg.match( /^--([^-][^=]+)(=(.*?))?$/ )
				if opt = get_id( $1 )
					last_opt = opt
					@options << last_opt
					@all << last_opt
				end
				if $2
					last_opt.value = $3
				end
			# if the last option has optional value, this would be it (if not set already by --foo=BAR)
			# else the ARGV argument becomes an argument
			else
				if last_opt && last_opt.has_optional_value? && last_opt.value == nil
					last_opt.value = arg
				else
					@arguments << arg
					@all << arg
				end
			end
		end
	end

	# find an option id in the map by it's short or long name
	# if found, then create Option object and return it
	# if not found, add option's name to @unknown_options and returns false
	def get_id( optname )
		@map.each { |id, params|
		 	if optname == params[0] ||
					optname == params[1]
					return Option.new( self, id )
			end
		}
		@unknown_options << optname
		false
	end

end # class SimpleOptionsParser


##############################
########## EXAMPLE ###########
##############################

if __FILE__ == $0

	require 'ostruct'

	# Firstly create options map, format is:
	# short argument, long argument, nil/:required/:optional parameter
	map = {
		:help      => [ 'h', 'help' ],
		:file      => [ 'f', 'file', :required ],
		:foo       => [ nil, 'foo', :required ],
		:extract   => [ 'x', 'extract' ],
		:preserve  => [ 'p', 'preserve' ],
		:gzip      => [ 'z', 'gzip' ]
	}

	# Parse ARGV using the map.
	if ARGV.empty?
	    argv = [ 'file3.txt', '-xf', 'file.tar.gz', '--gzip', '--foo=bar', 'file1.txt', 'file2.txt', '-p' ]
	else
	    argv = ARGV
	end
	op = SimpleOptionsParser.new( argv, map )

	# Check for ambiguous options.
	if ! op.unknown_options.empty?
		puts( "unknown options: " + op.unknown_options.join( ', ' ) )
	end

	# Create setup and set defaults.
	setup = OpenStruct.new
	setup.preserve = false
	setup.action = :add
	setup.gzip = false
	setup.archive = nil
	setup.files_to_process = []

	# Trace ARGV options.
	op.options.each do |opt|
		case opt.id
			when :help
				puts "HELP: You must..."
				exit 0
			when :file
				if ! opt.value
				    puts "ERROR: archive not specified"
				    #exit 1
				else
				    setup.archive = opt.value
				end
			when :extract
				setup.action = :extract
			when :preserve
				setup.preserve = true
			when :gzip
				setup.gzip = true
			when :foo
				setup.foo = opt.value
		end
	end

	# Files are standalone arguments, not options.
	# These standalone arguments may be placed anywhere, not only at the end of options.
	setup.files_to_process = op.arguments

	# Instead of checking missing options, check the setup.
	# Here, if the action is :add, we need some files as standalone arguments to be "added".
	if setup.action == :add
		if setup.files_to_process.empty?
			puts( "No files to add." )
			exit 1
		end
	end
	
	# print the setup
	print "setup: "
	p setup
	
	# print options IDs in their ARGV order
	print "options IDs: "
	p op.options.collect { |opt| opt.id }
	
	# print arguments in their ARGV order
	print "arguments: "
	p op.arguments
	
	# print both options and arguments in their ARGV order
	print "opts&args: "
	op.all.each { |x|
	    if x.is_a?( SimpleOptionsParser::Option )
	       print ':' + x.id.to_s
	    elsif x.is_a?( String )
	       print x
	    end
	    print( ', ' )
	}
	puts
	
end
