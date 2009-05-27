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

require 'fileutils'
require 'rexec/daemon/controller'

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

      # Returns some information relating to daemon startup problems
      def self.tail_err_log
        IO.popen("tail #{err_fn.dump}") do |io|
          return io.read
        end
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
