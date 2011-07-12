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

require 'fileutils'
require 'rexec/daemon/controller'
require 'rexec/reverse_io'

module RExec
  module Daemon
    # This class is the base daemon class. If you are writing a daemon, you should inherit from this class.
    class Base
      @@var_directory = nil
      @@log_directory = nil
      @@pid_directory = nil
      
      # Return the name of the daemon
      def self.daemon_name
        return name.gsub(/[^a-zA-Z0-9]+/, '-')
      end

      # Base directory for daemon log files / run files
      def self.var_directory
        @@var_directory || File.join("", "var")
      end
      
      # The directory the daemon will run in (Dir.chdir)
      def self.working_directory
        var_directory
      end

      # Return the directory to store log files in
      def self.log_directory
        @@log_directory || File.join(var_directory, "log", daemon_name)
      end

      # Standard log file for errors
      def self.err_fn
        File.join(log_directory, "stderr.log")
      end

      # Standard log file for normal output
      def self.log_fn
        File.join(log_directory, "stdout.log")
      end

      # Standard location of pid file
      def self.pid_directory
        @@pid_directory || File.join(var_directory, "run", daemon_name)
      end

      # Standard pid file
      def self.pid_fn
        File.join(pid_directory, "#{daemon_name}.pid")
      end

      # Mark the error log
      def self.mark_err_log
        fp = File.open(err_fn, "a")
        fp.puts "=== Error Log Opened @ #{Time.now.to_s} ==="
        fp.close
      end

      # Prints some information relating to daemon startup problems
      def self.tail_err_log(outp)
        lines = []
        
        File.open(err_fn, "r") do |fp|
          fp.seek_end

          fp.reverse_each_line do |line|
            lines << line
            break if line.match("=== Error Log") || line.match("=== Daemon Exception Backtrace")
          end
        end
        
        lines.reverse_each do |line|
          outp.puts line
        end
      end

      # Check the last few lines of the log file to find out if
      # the daemon crashed.
      def self.crashed?
        File.open(err_fn, "r") do |fp|
          fp.seek_end
          
          count = 2
          fp.reverse_each_line do |line|
            return true if line.match("=== Daemon Crashed")
            
            count -= 1
            
            break if count == 0
          end
        end
        
        return false
      end

      # Corresponds to controller method of the same name
      def self.daemonize
        Controller.daemonize(self)
      end

      # Corresponds to controller method of the same name
      def self.start
        Controller.start(self)
      end

      # Corresponds to controller method of the same name
      def self.stop
        Controller.stop(self)
      end

      # Corresponds to controller method of the same name
      def self.status
        Controller.status(self)
      end

      # The main function to setup any environment required by the daemon
      def self.prefork
        @@var_directory = File.expand_path(@@var_directory) if @@var_directory
        @@log_directory = File.expand_path(@@log_directory) if @@log_directory
        @@pid_directory = File.expand_path(@@pid_directory) if @@pid_directory
        
        FileUtils.mkdir_p(log_directory)
        FileUtils.mkdir_p(pid_directory)
      end
      
      # The main function to start the daemon
      def self.run
      end

      # The main function to stop the daemon
      def self.shutdown
      end
    end
  end
end
