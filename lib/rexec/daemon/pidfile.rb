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

module RExec
  module Daemon
    # This module controls the storage and retrieval of process id files.
    module PidFile
      # Saves the pid for the given daemon
      def self.store(daemon, pid)
        File.open(daemon.pid_fn, 'w') {|f| f << pid}
      end

      # Retrieves the pid for the given daemon
      def self.recall(daemon)
        IO.read(daemon.pid_fn).to_i rescue nil
      end

      # Removes the pid saved for a particular daemon
      def self.clear(daemon)
        if File.exist? daemon.pid_fn
          FileUtils.rm(daemon.pid_fn)
        end
      end

      # Checks whether the daemon is running by checking the saved pid and checking the corresponding process
      def self.running(daemon)
        pid = recall(daemon)

        return false if pid == nil

        gpid = Process.getpgid(pid) rescue nil

        return gpid != nil ? true : false
      end

      # Remove the pid file if the daemon is not running
      def self.cleanup(daemon)
        clear(daemon) unless running(daemon)
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
    end
  end
end
