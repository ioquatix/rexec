# Copyright (c) 2007, 2009 Samuel Williams. Released under the GNU GPLv3.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'rexec/daemon/pidfile'

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
        when 'stop'
          stop(daemon)
        when 'restart'
          puts "Stopping daemon..."
          attempts = 5

          while PidFile.running(daemon) == true and attempts > 0
            stop(daemon, attempts < 2)
            sleep 1
            attempts -= 1
          end

          if PidFile.running(daemon)
            puts "Could not kill daemon #{PidFile.recall(daemon)}"
            exit 1
          end

          puts "Starting daemon..."
          start(daemon)
        when 'status'
          puts status(daemon)
        else
          puts "Invalid command. Please specify start, stop or restart."
          exit
        end
      end

      # This function closes all IO other than $stdin, $stdout, $stderr
      def self.close_io
        # Make sure all file descriptors are closed
        ObjectSpace.each_object(IO) do |io|
          unless [$stdin, $stdout, $stderr].include?(io)
            io.close rescue nil
          end
        end
      end

      # This function starts the supplied daemon
      def self.start(daemon)
        case status(daemon)
        when :running
          $stderr.puts "Daemon already running PID #{PidFile.recall(daemon)}!"
          return
        when :unknown
          $stderr.puts "Daemon in unknown state (may have crashed?). Was PID #{PidFile.recall(daemon)}! Will clear previous state and continue."
          PidFile.clear(daemon)
        end

        daemon.prefork

        fork do
          Process.setsid
          exit if fork

          PidFile.store(daemon, Process.pid)

          File.umask 0000
          Dir.chdir daemon.working_directory

          $stdin.reopen "/dev/null"
          $stdout.reopen daemon.log_fn, "a"
          $stderr.reopen daemon.err_fn, "a"

          # Close all IO other than the above std pipes
          close_io
          
          main = Thread.new do
            begin
              daemon.run
            rescue
              $stderr.puts $!
            end
          end

          trap("TERM") do
            daemon.shutdown
            main.exit
          end

          main.join
          PidFile.clear(daemon)
        end

        puts "Daemon starting..."

        timer = TIMEOUT
        pid = nil
        while pid == nil and timer > 0
          sleep 1
          pid = PidFile.recall(daemon)
          puts "Waiting for daemon to start (#{timer}/#{TIMEOUT})"
          timer -= 1
        end

        if PidFile.running(daemon)
          puts "Daemon started: #{pid}"
          return true
        else
          puts "Daemon status unknown..."
          $stdout.write daemon.tail_err_log
          return false
        end
      end

      # This function returns the status of the daemon. This can be one of <tt>:running</tt>, <tt>:unknown</tt> (pid file exists but no 
      # corresponding process can be found) or <tt>:stopped</tt>.
      def self.status(daemon)
        if File.exist? daemon.pid_fn
          return PidFile.running(daemon) ? :running : :unknown
        else
          return :stopped
        end
      end

      # Stops the daemon process.
      def self.stop(daemon, kill=false)
        if !File.file?(daemon.pid_fn)
          puts "Pid file not found. Is the daemon running?"
          return false
        end

        unless PidFile.running(daemon)
          puts "Daemon not running? Clearing pid file."
          PidFile.clear(daemon)
          return false
        end

        pid = PidFile.recall(daemon)

        sig = kill ? "KILL" : "TERM"

        puts "Sending #{sig}..."

        pid && Process.kill(sig, pid)
        return true
      end
    end
  end
end