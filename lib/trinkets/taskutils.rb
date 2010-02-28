# TITLE:
#
#   TaskUtils
#
# SUMMARY:
#
#   All the task methods used by BatchRunner.
#
# COPYRIGHT:
#
#   Copyright (c) 2007 7rans

require 'yaml'
require 'fileutils'

require 'forge/utils/consoleutils'
require 'forge/utils/emailutils'
#require 'rivets/to_params'

require 'facets/hash/reverse'  # funny name for this lib!!!

# = TaskUtils
#
#

module TaskUtils
  include ConsoleUtils
  include EmailUtils

  module_function

  #

  def argv
    @argv ||= ARGV.dup
  end

  #

  def task_cache
    @task_cache ||= {}
  end

  # Abort task.

  def abort(msg=nil)
    puts msg if msg
    exit 0
  end

  # Convert command line argv to args.
  #
  # TODO Is this implmented as expected?

  def command_parameters
    argv.to_params
  end

  # Is a task complete or in the process of being completed?

  def done?(task)
    task == $0 or task_cache.key?(task)
  end


  ################
  # Global Flags #
  ################

  #

  def trace?
    @trace ||= %w{--trace}.any?{|a| argv.delete(a)}
  end

  #

  def trace!
    @trace = true
  end

  #

  def noharm?
    @noharm ||= %w{--dryrun --dry-run --noharm}.any?{|a| argv.delete(a)}
  end

  alias_method :dryrun?, :noharm? ; module_function :dryrun?

  #

  def noharm!
    @noharm = true
  end
  alias_method :dryrun!, :noharm! ; module_function :dryrun!


  ######################
  # Configuration Data #
  ######################

  # ProjectInfo, if available.

  def projectinfo
    @projectinfo
  end

  # Possible locations of a configuration file.
  # These can be in the task directory under:
  #
  #   config
  #   etc/+name+
  #   conf/+name+
  #
  # Or in the project directory under:
  #
  #   info/+name+
  #   .+name+
  #
  # Since they are Yaml files, they can optionally
  # end with '.yaml' or '.yml'.
  #
  # TODO Think more about where config files can/should
  # be located.
  #++

  def config_file(name)
    util_dir = File.dirname($0)
    locations = [
      "#{util_dir}/config",
      "#{util_dir}/conf/%s",
      "#{util_dir}/etc/%s",
      "info/%s",
      ".%s"
    ]
    locations = locations.collect { |l| (l % [name]) + "{,.yml,.yaml}" }
    Dir.glob("{" + locations.join(",") + "}")[0]
  end

  # Load task configuration if any.
  # This will look for a section in a config.yaml
  # file, or with the given name as "etc/-name-.yaml".
  #
  # (The yaml extension is optional, and .yml is supported.)

  def config_load(*names) #, defaults=nil)
    names.inject({}) do |memo, name|
      name     = name.to_s
      #defaults = defaults || {}
      config   = {}

      if file = config_file(name)
        config = YAML.load(File.open(file))

        if file =~ /config([.]yaml|[.]yml|)$/
          config = config[name]
        end
      end

      config.update(memo)
    end
    #return defaults.update(config || {})
  end

  #

  def config_vector(config, args_field=nil)
    config = config.dup
    if args_field
      args = [config.delete(args_field)].flatten.compact
    else
      args = []
    end
    args << config
    return args
  end


  ##################
  # Shell Features #
  ##################

  def sh(cmd)
    if noharm?
      puts cmd
      true
    else
      puts "--> system call: #{cmd}" if trace?
      system(cmd)
    end
  end


  ##########################
  # Add FileUtils Features #
  ##########################

  FileUtils.private_instance_methods(false).each do |meth|
    next if meth =~ /^fu_/
    module_eval %{
      def #{meth}(*a,&b)
        fileutils.#{meth}(*a,&b)
      end
    }
  end

  # Delegate access to FileUtils.

  def fileutils
    dryrun? ? ::FileUtils::DryRun : ::FileUtils
  end

  # Bonus FileUtils features.

  def cd(*a,&b)
    puts "cd #{a}" if dryrun?
    fileutils.chdir(*a,&b)
  end


  #########################
  # Add FileTest Features #
  #########################

  FileTest.private_instance_methods(false).each do |meth|
    next if meth =~ /^fu_/
    module_eval %{
      def #{meth}(*a,&b)
        FileTest.#{meth}(*a,&b)
      end
    }
  end

  # Is a given path a regular file? If +path+ is a glob
  # then checks to see if all matches are refular files.

  def file?(path)
    paths = Dir.glob(path)
    paths.not_empty? && paths.all?{ |f| FileTest.file?(f) }
  end

  # Assert that a given path is a file.

  def file!(path)
    abort "file not found #{path}" unless file?(path)
  end

  # Is a given path a directory? If +path+ is a glob
  # checks to see if all matches are directories.

  def dir?(path)
    paths = Dir.glob(path)
    paths.not_empty? && paths.all?{ |f| FileTest.directory?(f) }
  end
  alias_method :directory?, :dir? ; module_function :directory?

  # Assert that a given path is a directory.

  def dir!(path)
    abort "directory not found #{path}" unless dir?(path)
  end
  alias_method :directory!, :dir! ; module_function :directory!

  # Okay, I'm being a dork, but 'fold' seems like a better word
  # then 'dir', 'folder', or 'directory'.

  def fold?(path)
    paths = Dir.glob(path)
    paths.not_empty? && paths.all?{ |f| FileTest.directory?(f) }
  end

  # Assert that a given path is a fold (ie. a folder).

  def fold!(path)
    abort "fold not found #{path}" unless fold?(path)
  end

  # Assert that a path exists.

  def exists?(path)
    paths = Dir.glob(path)
    paths.not_empty?
  end
  alias_method :exist?, :exists? ; module_function :exist?
  alias_method :path?,  :exists? ; module_function :path?

  # Assert that a path exists.

  def exists!(path)
    abort "path not found #{path}" unless exists?(path)
  end
  alias_method :exist!, :exists! ; module_function :exist!
  alias_method :path!,  :exists! ; module_function :path!

  # Is a file a task?

  def task?(path)
    task = File.dirname($0) + "/#{path}"
    task.chomp!('!')
    task if FileTest.file?(task) && FileTest.executable?(task)
  end

  # Is a file a command executable?
  #
  # TODO Probably needs to be fixed for Windows.

  def bin?(path)
    is_bin = command_paths.any? do |f|
      FileTest.exist?(File.join(f, path))
    end
    is_bin ? File.basename(path) : false
  end

  # This is a support method of #bin?

  def command_paths
    @command_paths ||= ENV['PATH'].split(':')
  end

end
