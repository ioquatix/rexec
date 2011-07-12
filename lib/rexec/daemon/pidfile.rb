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

			# This function returns the status of the daemon. This can be one of +:running+, +:unknown+ (pid file exists but no 
			# corresponding process can be found) or +:stopped+.
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
