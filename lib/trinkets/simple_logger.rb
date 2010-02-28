# (c) Jan Molic
# licence: Ruby's

require 'thread'
require 'yaml'

class SimpleLogger

	def initialize( output )
		@mutex = Mutex.new
		@output = output
		@level = 0
	end

	def level= sym
		case sym
			when :debug
				@level = 0
			when :info
				@level = 1
			when :warn
				@level = 2
			when :error
				@level = 3
			when :fatal
				@level = 4
			else
				@level = 0
		end
	end

	# hsh may be: { :backtrace=>err.backtrace }
	def output( name, msg, hsh )
		@mutex.synchronize {
			now = Time.now
			time = now.strftime( "%Y-%m-%d_%H:%M:%S." ) + now.usec.to_s.ljust( 6 )
			lvl = ( name.to_s.upcase + ':' ).ljust( 6 )
			@output.puts( "#{time} #{lvl} #{msg}" )
			if hsh
				hsh.each { |k,v|
					@output.puts( "  -> #{k}: ")
					if v.is_a?( String )
						ary = v.split( "\n" )
					else
						ary = v.to_yaml.split( "\n" )
						if ary.first == '--- ' # get rid of YAML's document start
							ary.shift
						end
					end
					@output.puts( ary.collect { |x| "     " + x.strip }.join( "\n" ) )
				}
			end
		}
	end

	def method_missing( name, msg, hsh=nil )
		if ( name == :debug && @level <= 0 ) ||
			( name == :info && @level <= 1 ) ||
			( name == :warn && @level <= 2 ) ||
			( name == :error && @level <= 3 ) ||
			( name == :fatal && @level <= 4 )
			output( name, msg, hsh )
		end
	end

end


if __FILE__ == $0

	$log = SimpleLogger.new( STDOUT )

	$log.info( 'This is really foo!', :var1=>'foo', :var2=>'bar' )
	$log.warn( 'This is really bar!', :detail=>[1,2,3,4] )
	$log.error( 'This is foo again!', :detail=>{:a=>:b} )

	begin
		raise 'file not found'
	rescue Exception => err
		$log.fatal( 'Something is wrong.', :error=>err.to_s, :backtrace=>err.backtrace )
	end

end
