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
		#
		# The basic structure of a daemon is as follows:
		# 	
		# 	class Server < RExec::Daemon::Base
		# 		def self.run
		# 			# Long running process, e.g. web server, game server, etc.
		# 		end
		# 	end
		# 	
		# 	Server.daemonize
		#
		# The base directory specifies a path such that:
		#   working_directory = #{@@base_directory}/#{daemon_name}
		#   log_directory = #{working_directory}/log
		#   log_file_path = #{log_directory}/daemon.log
		#   runtime_directory = #{working_directory}/run
		#   process_file_path = #{runtime_directory}/daemon.pid
		class Base
			# For a system-level daemon you might want to specify "/var"
			@@base_directory = "."

			# Return the name of the daemon
			def self.daemon_name
				return name.gsub(/[^a-zA-Z0-9]+/, '-')
			end

			# The directory the daemon will run in.
			def self.working_directory
				@@base_directory
			end

			# Return the directory to store log files in.
			def self.log_directory
				File.join(working_directory, "log")
			end

			# Standard log file for stdout and stderr.
			def self.log_file_path
				File.join(log_directory, "#{daemon_name}.log")
			end

			# Runtime data directory for the daemon.
			def self.runtime_directory
				File.join(working_directory, "run")
			end

			# Standard location of process pid file.
			def self.process_file_path
				File.join(runtime_directory, "#{daemon_name}.pid")
			end

			# Mark the output log.
			def self.mark_log
				File.open(log_file_path, "a") do |log_file|
					log_file.puts "=== Log Marked @ #{Time.now.to_s} ==="
				end
			end

			# Prints some information relating to daemon startup problems.
			def self.tail_log(output)
				lines = []

				File.open(log_file_path, "r") do |log_file|
					log_file.seek_end

					log_file.reverse_each_line do |line|
						lines << line
						break if line.match("=== Log Marked") || line.match("=== Daemon Exception Backtrace")
					end
				end

				lines.reverse_each do |line|
					output.puts line
				end
			end

			# Check the last few lines of the log file to find out if the daemon crashed.
			def self.crashed?
				File.open(log_file_path, "r") do |log_file|
					log_file.seek_end

					count = 3
					log_file.reverse_each_line do |line|
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
				@@base_directory = File.expand_path(@@base_directory) if @@base_directory

				FileUtils.mkdir_p(log_directory)
				FileUtils.mkdir_p(runtime_directory)
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
