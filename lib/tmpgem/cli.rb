module Tmpgem
  class CLI
    class CommandExecutionError < StandardError; end

    def initialize(argv)
      @argv = argv
      @debug = false
    end

    def run
      parse_args

      gemspecs = Dir.glob('*.gemspec')
      unless gemspecs.size == 1
        $stderr.puts "gemspec must be one, but got #{gemspecs.join(', ')}."
        return 1
      end
      gemspec = gemspecs.first
      fname = build(gemspec)

      backup_original(fname) do
        install(fname)
        puts "#{fname} is installed temporary. Please CTRL-C when you do not need this gem."
        sleep
      end
      return 0
    end

    private

    def parse_args
      opt = OptionParser.new
      opt.on('-d', '--debug') { @debug = true }
      opt.parse!(@argv)
    end

    def capture3!(*cmd)

      Open3.capture3(*cmd).tap do |out, err, status|
        msg = <<~MSG
          Cmd: #{cmd.join(' ')}
          Status: #{status.exitstatus}
          STDOUT:
          #{out}
          STDERR:
          #{err}
        MSG
        debug_log("Command is executed.\n" + msg)

        unless status.success?
          raise CommandExecutionError, "Command Execution is failed\n" + msg
        end
      end
    end

    def debug?
      @debug
    end

    def debug_log(*args)
      return unless debug?
      $stderr.puts(*args)
    end

    # @return [String] `*.gem` filename
    def build(gemspec)
      out, _err, _status = capture3!('gem', 'build', gemspec)
      out.each_line.find do |line|
        break $1 if line =~ /^  File: (.+)/
      end
    end

    def install(fname)
      capture3!('gem', 'install', '--local', fname)
    end

    def backup_original(fname)
      cache = Gem.path.find do |dir|
        cache = Pathname(dir) / 'cache' / fname
        break cache if cache.exist?
      end

      unless cache
        yield
        return
      end

      Dir.mktmpdir do |tmpdir|
        tmpfile = Pathname(tmpdir) / fname
        debug_log cache
        debug_log tmpfile
        FileUtils.cp(cache, tmpfile)
        begin
          yield
        rescue Interrupt
          puts 'Restoring the gem...'
          gemname = gemname(fname)
          version = version(fname)
          capture3!('gem', 'uninstall', gemname, '--version', version, '--ignore-dependencies')
          FileUtils.cp(tmpfile, cache)
          capture3!('gem', 'install', '--local', gemname, chdir: File.dirname(tmpfile))
          puts "#{gemname(fname)} is restored!"
        end
      end
    end

    def gemname(fname)
      fname.match(/^(.+)-([^-]+)\.gem$/)[1]
    end

    def version(fname)
      fname.match(/^(.+)-([^-]+)\.gem$/)[2]
    end
  end
end
