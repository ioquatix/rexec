# Copyright (c) 2007, 2009, 2011 Samuel G. D. Williams. <http://www.oriontransfer.co.nz>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'rexec/daemon/pidfile'
require 'rexec/task'

module RExec
  module Daemon
    # Daemon startup timeout
    TIMEOUT = 5
    
    # This module contains functionality related to starting and stopping the daemon, and code for processing command line input.
    module Controller
      # This function is called from the daemon executable. It processes ARGV and checks whether the user is asking for
      # <tt>start</tt>, <tt>stop</tt>, <tt>restart</tt> or <tt>status</tt>.
      def self.daemonize(daemon)
        #puts "Running in #{WorkingDirectory}, logs in #{LogDirectory}"
        case !ARGV.empty? && ARGV[0]
        when 'start'
          start(daemon)
          status(daemon)
        when 'stop'
          stop(daemon)
          status(daemon)
          PidFile.cleanup(daemon)
        when 'restart'
          stop(daemon)
          PidFile.cleanup(daemon)
          start(daemon)
          status(daemon)
        when 'status'
          status(daemon)
        else
          puts "Invalid command. Please specify start, restart, stop or status."
          exit
        end
      end

      # This function starts the supplied daemon
      def self.start(daemon)
        puts "Starting daemon..."
        
        case PidFile.status(daemon)
        when :running
          $stderr.puts "Daemon already running!"
          return
        when :stopped
          # We are good to go...
        else
          $stderr.puts "Daemon in unknown state! Will clear previous state and continue."
          status(daemon)
          PidFile.clear(daemon)
        end

        daemon.prefork
        daemon.mark_err_log

        fork do
          Process.setsid
          exit if fork

          PidFile.store(daemon, Process.pid)

          File.umask 0000
          Dir.chdir daemon.working_directory

          $stdin.reopen "/dev/null"
          $stdout.reopen daemon.log_fn, "a"
          $stderr.reopen daemon.err_fn, "a"

          main = Thread.new do
            begin
              daemon.run
            rescue
              $stderr.puts "=== Daemon Exception Backtrace @ #{Time.now.to_s} ==="
              $stderr.puts "#{$!.class}: #{$!.message}"
              $!.backtrace.each { |at| $stderr.puts at }
              $stderr.puts "=== Daemon Crashed ==="
              
              $stderr.flush
            end
          end

					trap("INT") do
						daemon.shutdown
						main.exit
					end

          trap("TERM") do
            exit!
          end

          main.join
        end

        puts "Waiting for daemon to start..."
        sleep 0.1
        timer = TIMEOUT
        pid = PidFile.recall(daemon)
        
        while pid == nil and timer > 0
          # Wait a moment for the forking to finish...
          puts "Waiting for daemon to start (#{timer}/#{TIMEOUT})"
          sleep 1
          
          # If the daemon has crashed, it is never going to start...
          break if daemon.crashed?
          
          pid = PidFile.recall(daemon)
          
          timer -= 1
        end
      end

      # Prints out the status of the daemon
      def self.status(daemon)
        case PidFile.status(daemon)
        when :running
          puts "Daemon status: running pid=#{PidFile.recall(daemon)}"
        when :unknown
          if daemon.crashed?
            puts "Daemon status: crashed"
            
            $stdout.flush
            daemon.tail_err_log($stderr)
          else
            puts "Daemon status: unknown"
          end
        when :stopped
          puts "Daemon status: stopped"
        end
      end

      # Stops the daemon process.
      def self.stop(daemon)
        puts "Stopping daemon..."
        
        # Check if the pid file exists...
        if !File.file?(daemon.pid_fn)
          puts "Pid file not found. Is the daemon running?"
          return
        end

        pid = PidFile.recall(daemon)

        # Check if the daemon is already stopped...
        unless PidFile.running(daemon)
          puts "Pid #{pid} is not running. Has daemon crashed?"
          return
        end

        pid = PidFile.recall(daemon)
        Process.kill("INT", pid)
        sleep 0.1
        
        # Kill/Term loop - if the daemon didn't die easily, shoot
        # it a few more times.
        attempts = 5
        while PidFile.running(daemon) and attempts > 0
          sig = (attempts < 2) ? "KILL" : "TERM"
          
          puts "Sending #{sig} to pid #{pid}..."
          Process.kill(sig, pid)
          
          sleep 1 unless first
          attempts -= 1
        end
        
        # If after doing our best the daemon is still running (pretty odd)...
        if PidFile.running(daemon)
          puts "Daemon appears to be still running!"
          return
        end
        
        # Otherwise the daemon has been stopped.
        PidFile.clear(daemon)
      end
    end
  end
end