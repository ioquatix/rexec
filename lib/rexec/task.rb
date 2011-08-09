# Copyright (c) 2007, 2011 Samuel G. D. Williams. <http://www.oriontransfer.co.nz>
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

require 'thread'

module RExec
	private
	
	RD = 0
	WR = 1
	
	public

	# Cloose all IO other than $stdin, $stdout, $stderr (or those given by the argument except)
	def self.close_io(except = [$stdin, $stdout, $stderr])
		# Make sure all file descriptors are closed
		ObjectSpace.each_object(IO) do |io|
			unless except.include?(io)
				io.close rescue nil
			end
		end
	end

	# Represents a running process, either a child process or a background/daemon process.
	# Provides an easy high level interface for managing process life-cycle.
	class Task
		private
		def self.pipes_for_options(options)
			pipes = [[nil, nil], [nil, nil], [nil, nil]]

			if options[:passthrough]
				passthrough = options[:passthrough]

				if passthrough == :all
					passthrough = [:in, :out, :err]
				elsif passthrough.kind_of?(Symbol)
					passthrough = [passthrough]
				end

				passthrough.each do |name|
					case(name)
					when :in
						options[:in] = $stdin
					when :out
						options[:out] = $stdout
					when :err
						options[:err] = $stderr
					end
				end
			end

			modes = [RD, WR, WR]
			{:in => 0, :out => 1, :err => 2}.each do |name, idx|
				m = modes[idx]
				p = options[name]

				if p.kind_of?(IO)
					pipes[idx][m] = p
				elsif p.kind_of?(Array) and p.size == 2
					pipes[idx] = p
				else
					pipes[idx] = IO.pipe
				end
			end

			return pipes
		end

		# The standard process pipes.
		STDPIPES = [STDIN, STDOUT, STDERR]
		
		# Close all the supplied pipes.
		def self.close_pipes(*pipes)
			pipes = pipes.compact.reject{|pipe| STDPIPES.include?(pipe)}

			pipes.each do |pipe|
				pipe.close unless pipe.closed?
			end
		end

		# Dump any remaining data from the pipes, until they are closed.
		def self.dump_pipes(*pipes)
			pipes = pipes.compact.reject{|pipe| STDPIPES.include?(pipe)}

			pipes.delete_if { |pipe| pipe.closed? }
			# Dump any output that was not consumed (errors, etc)
			while pipes.size > 0
				result = IO.select(pipes)

				result[0].each do |pipe|
					if pipe.closed? || pipe.eof?
						pipes.delete(pipe)
						next
					end

					$stderr.puts pipe.readline.chomp
				end
			end
		end

		public
		# Returns true if the given pid is a current process
		def self.running?(pid)
			gpid = Process.getpgid(pid) rescue nil

			return gpid != nil ? true : false
		end

		# Very simple method to spawn a child daemon. A daemon is detatched from the controlling tty, and thus is
		# not killed when the parent process finishes.
		#
		#	spawn_daemon do
		#		Dir.chdir("/")
		#		File.umask 0000
		#		puts "Hello from daemon!"
		#		sleep(600)
		#		puts "This code will not quit when parent process finishes..."
		#		puts "...but $stdout might be closed unless you set it to a file."
		#	end
		def self.spawn_daemon(&block)
			pid_pipe = IO.pipe

			fork do
				Process.setsid
				exit if fork

				# Send the pid back to the parent
				pid_pipe[RD].close
				pid_pipe[WR].write(Process.pid.to_s)
				pid_pipe[WR].close

				yield

				exit(0)
			end

			pid_pipe[WR].close
			pid = pid_pipe[RD].read
			pid_pipe[RD].close

			return pid.to_i
		end

		# Very simple method to spawn a child process
		# 
		#	spawn_child do
		#		puts "Hello from child!"
		#	end
		def self.spawn_child(&block)
			pid = fork do
				yield

				exit!(0)
			end

			return pid
		end

		# Open a process. Similar to +IO.popen+, but provides a much more generic interface to +stdin+, +stdout+,
		# +stderr+ and the +pid+. We also attempt to tidy up as much as possible given some kind of error or
		# exception. You may write to +output+, and read from +input+ and +error+.
		#
		# Typical usage looks similar to +IO.popen+:
		# 	count = 0
		# 	result = Task.open(["ls", "-la"], :passthrough => :err) do |task|
		# 		count = task.output.read.split(/\n/).size
		# 	end
		# 	puts "Count: #{count}" if result.exitstatus == 0
		#
		# The basic command can simply be a string, and this will be passed to +Kernel#exec+ which will perform
		# shell expansion on the arguments.
		#
		# If the command passed is an array, this will be executed without shell expansion.
		#
		# If a +Proc+ (or anything that +respond_to? :call+) is provided, this will be executed in the child
		# process. Here is an example of a long running background process:
		#
		# 	daemon = Proc.new do
		# 		# Long running process
		# 		sleep(1000)
		# 	end
		# 	
		# 	task = Task.open(daemon, :daemonize => true, :in => ..., :out => ..., :err => ...)
		# 	exit(0)
		#
		# ==== Options
		#
		# [+:passthrough+, +:in+, +:out+, +:err+]
		#   The current process (e.g. ruby) has a set of existing pipes +$stdin+, +$stdout+ and 
		#   +$stderr+. These pipes can also be used by the child process. The passthrough option
		#   allows you to specify which pipes are retained from the parent process by the child.
		#   
		#   Typically it is useful to passthrough $stderr, so that errors in the child process
		#   are printed out in the terminal of the parent process:
		#   	Task.open([...], :passthrough => :err)
		#   	Task.open([...], :passthrough => [:in, :out, :err])
		#   	Task.open([...], :passthrough => :all)
		#   
		#   It is also possible to redirect to files, which can be useful if you want to keep a
		#   a log file:
		#   	Task.open([...], :out => File.open("output.log"))
		#   
		#   The default behaviour is to create a new pipe, but any pipe (e.g. a network socket)
		#   could be used:
		#   	Task.open([...], :in => IO.pipe)
		#   
		# [+:daemonize+]
		#   The process that is opened may be detached from the parent process. This allows the
		#   child process to exist even if the parent process exits. In this case, you will also
		#   probably want to specify the +:passthrough+ option for log files:
		#   	Task.open([...],
		#   		:daemonize => true,
		#   		:in => File.open("/dev/null"),
		#   		:out => File.open("/var/log/child.log", "a"),
		#   		:err => File.open("/var/log/child.err", "a")
		#   	)
		#
		# [+:env+, +:env!+]
		#   Provide a environment which will be used by the child process. Use +:env+ to update
		#   the exsting environment and +:env!+ to replace it completely.
		#   	Task.open([...], :env => {'foo' => 'bar'})
		#
		# [+:umask+]
		#    Set the umask for the new process, as per +File.umask+.
		#
		# [+:chdir+]
		#    Set the current working directory for the new process, as per +Dir.chdir+.
		#
		# [+:preflight+]
		#    Similar to a proc based command, but executed before execing the given process.
		#    	preflight = Proc.new do |command, options|
		#    		# Setup some default state before exec the new process.
		#    	end
		#    	
		#    	Task.open([...], :preflight => preflight)
		#    
		#    The options hash is passed directly so you can supply custom arguments to the preflight
		#    function.
		
		def self.open(command, options = {}, &block)
			cin, cout, cerr = pipes_for_options(options)
			spawn = options[:daemonize] ? :spawn_daemon : :spawn_child

			cid = self.send(spawn) do
				close_pipes(cin[WR], cout[RD], cerr[RD])

				STDIN.reopen(cin[RD]) if cin[RD]
				STDOUT.reopen(cout[WR]) if cout[WR]
				STDERR.reopen(cerr[WR]) if cerr[WR]

				if options[:env!]
					ENV.clear
					ENV.update(options[:env!])
				elsif options[:env]
					ENV.update(options[:env])
				end

				if options[:umask]
					File.umask(options[:umask])
				end

				if options[:chdir]
					Dir.chdir(options[:chdir])
				end

				if options[:preflight]
					preflight.call(command, options)
				end

				if command.respond_to? :call
					command.call
				elsif Array === command
					command = command.dup
					
					# If command is a Pathname, we need to convert it to an absolute path if possible,
					# otherwise if it is relative it might cause problems.
					if command[0].respond_to? :realpath
						command[0] = command[0].realpath
					end
					
					# exec expects an array of Strings:
					command.collect! { |item| item.to_s }
					
					exec *command
				else
					if command.respond_to? :realpath
						command = command.realpath
					end
					
					exec command.to_s
				end
			end

			close_pipes(cin[RD], cout[WR], cerr[WR])

			task = Task.new(cin[WR], cout[RD], cerr[RD], cid)

			if block_given?
				begin
					yield task
					
					# Close all input pipes if not done already.
					task.close_input
					
					# The task has stopped if task.wait returns correctly.
					return task.wait
				rescue Interrupt
					# If task.wait is interrupted, we should also interrupt the child process
					task.kill
				ensure
					# Print out any remaining data from @output or @error
					task.close
				end
			else
				return task
			end
		end

		def initialize(input, output, error, pid)
			@input = input
			@output = output
			@error = error

			@pid = pid

			@result = nil
			@status = :running
			@result_lock = Mutex.new
			@result_available = ConditionVariable.new
		end

		# Standard input to the running task.
		attr :input
		
		# Standard output from the running task.
		attr :output
		
		# Standard error from the running task.
		attr :error
		
		# The PID of the running task.
		attr :pid
		
		# The status of the task after calling task.wait.
		attr :result

		# Returns true if the current task is still running
		def running?
			if self.class.running?(@pid)
				# The pid still seems alive, check that it isn't some other process using the same pid...
				@result_lock.synchronize do
					# If we haven't waited for it yet, it must be either a running process or a zombie...
					return @status != :stopped
				end
			end
			
			return false
		end

		# Close all connections to the child process
		def close
			begin
				self.class.dump_pipes(@output, @error)
			ensure
				self.class.close_pipes(@input, @output, @error)
			end
		end

		# Close input pipe to child process (if applicable)
		def close_input
			@input.close if @input and !@input.closed?
		end

		# Send a signal to the child process
		def kill(signal = "INT")
			if running?
				Process.kill(signal, @pid)
			else
				raise Errno::ECHILD
			end
		end

		# Wait for the child process to finish, return the exit status.
		# This function can be called from multiple threads.
		def wait
			begin_wait = false
			
			# Check to see if some other caller is already waiting on the result...
			@result_lock.synchronize do
				case @status
				when :waiting
					# If so, wait for the wait to finish...
					@result_available.wait(@result_lock)
				when :running
					# Else, mark that we should begin waiting...
					begin_wait = true
					@status = :waiting
				when :stopped
					return @result
				end
			end
			
			# If we should begin waiting (the first thread to wait)...
			if begin_wait
				begin
					# Wait for the result...
					_pid, @result = Process.wait2(@pid)
				end
				
				# The result is now available...
				@result_lock.synchronize do
					@status = :stopped
				end
				
				# Notify other threads...
				@result_available.broadcast()
			end
			
			# Return the result
			return @result
		end

		# Forcefully stop the child process.
		def stop
			if running?
				close_input
				kill
			end
		end
	end
end
