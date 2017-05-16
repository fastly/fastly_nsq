# frozen_string_literal: true
$stdout.sync = true

require 'erb'
require 'fastly_nsq'
require 'fileutils'
require 'optparse'
require 'singleton'
require 'yaml'

class FastlyNsq::CLI
  include Singleton

  attr_reader :options, :launcher

  def parse_options(args = ARGV)
    parse(args)
    setup_logger
    check_pid
    damonize if damonize?
    write_pid
  end

  def run
    require options[:require] if options[:require]

    read_io = trap_signals

    FastlyNsq.logger.info "Running in #{RUBY_DESCRIPTION}"

    # Before this point, the process is initializing with just the main thread.
    # Starting here the process will now have multiple threads running.

    unless options[:daemon]
      FastlyNsq.logger.info 'Starting processing, hit Ctrl-C to stop'
    end

    require 'fastly_nsq/launcher'
    require 'fastly_nsq/manager'
    @launcher = FastlyNsq::Launcher.new(options)

    begin
      launcher.run

      while readable_io = IO.select([read_io])
        signal = readable_io.first[0].gets.strip
        handle_signal signal
      end
    rescue Interrupt
      FastlyNsq.logger.info 'Shutting down'
      launcher.stop
      # Explicitly exit so busy Processor threads can't block
      # process shutdown.
      FastlyNsq.logger.info 'Bye!'
      exit(0)
    end
  end

  private

  def parse(args)
    opts = {}

    @parser = OptionParser.new do |o|
      o.on '-d', '--daemon', 'Daemonize process' do |arg|
        opts[:daemonize] = arg
      end

      o.on '-L', '--logfile PATH', 'path to writable logfile' do |arg|
        opts[:logfile] = arg
      end

      o.on '-P', '--pidfile PATH', 'path to pidfile' do |arg|
        opts[:pidfile] = arg
      end

      o.on '-r', '--require [PATH|DIR]', 'Location of message_processor definition' do |arg|
        opts[:require] = arg
      end

      o.on '-v', '--verbose', 'enable verbose logging output' do |arg|
        opts[:verbose] = arg
      end
    end

    @parser.banner = 'fastly_nsq [options]'
    @parser.parse!(args)

    @options = opts
  end

  def check_pid
    if pidfile?
      case pid_status(pidfile)
      when :running, :not_owned
        puts "A server is already running. Check #{pidfile}"
        exit(1)
      when :dead
        File.delete(pidfile)
      end
    end
  end

  def pid_status(pidfile)
    return :exited unless File.exist?(pidfile)
    pid = ::File.read(pidfile).to_i
    return :dead if pid == 0
    Process.kill(0, pid) # check process status
    :running
  rescue Errno::ESRCH
    :dead
  rescue Errno::EPERM
    :not_owned
  end

  def setup_logger
    FastlyNsq.logger = Logger.new(options[:logfile]) if options[:logfile]

    FastlyNsq.logger.level = ::Logger::DEBUG if options[:verbose]
  end

  def write_pid
    if pidfile?
      begin
        File.open(pidfile, ::File::CREAT | ::File::EXCL | ::File::WRONLY) do |f|
          f.write Process.pid.to_s
        end
        at_exit { File.delete(pidfile) if File.exist?(pidfile) }
      rescue Errno::EEXIST
        check_pid
        retry
      end
    end
  end

  def trap_signals
    self_read, self_write = IO.pipe
    sigs = %w(INT TERM TTIN USR1)

    sigs.each do |sig|
      begin
        trap sig do
          self_write.puts(sig)
        end
      rescue ArgumentError
        puts "Signal #{sig} not supported"
      end
    end
    self_read
  end

  def handle_signal(sig)
    FastlyNsq.logger.debug "Got #{sig} signal"
    case sig
    when 'INT'
      # Handle Ctrl-C in JRuby like MRI
      # http://jira.codehaus.org/browse/JRUBY-4637
      raise Interrupt
    when 'TERM'
      # Heroku sends TERM and then waits 10 seconds for process to exit.
      raise Interrupt
    when 'USR1'
      FastlyNsq.logger.info 'Received USR1, no longer accepting new work'
      launcher.quiet
    when 'TTIN'
      Thread.list.each do |thread|
        FastlyNsq.logger.warn "Thread TID-#{thread.object_id.to_s(36)} #{thread['fastly_nsq_label']}"
        if thread.backtrace
          FastlyNsq.logger.warn thread.backtrace.join("\n")
        else
          FastlyNsq.logger.warn '<no backtrace available>'
        end
      end
    end
  end

  def damonize
    return unless options[:daemonize]

    files_to_reopen = []
    ObjectSpace.each_object(File) do |file|
      files_to_reopen << file unless file.closed?
    end

    ::Process.daemon(true, true)

    files_to_reopen.each do |file|
      begin
        file.reopen file.path, 'a+'
        file.sync = true
      rescue ::Exception
      end
    end

    [$stdout, $stderr].each do |io|
      File.open(options.fetch(:logfile, '/dev/null'), 'ab') do |f|
        io.reopen(f)
      end
      io.sync = true
    end
    $stdin.reopen('/dev/null')

    setup_logger
  end

  def logfile?
    !logfile.nil?
  end

  def pidfile?
    !pidfile.nil?
  end

  def damonize?
    options[:daemonize]
  end

  def logfile
    options[:logfile]
  end

  def pidfile
    options[:pidfile]
  end
end
