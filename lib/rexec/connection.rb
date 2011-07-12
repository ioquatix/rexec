# Copyright (c) 2007, 2011 Samuel G. D. Williams. <http://www.oriontransfer.co.nz>
# Released under the MIT license. Please see LICENSE.txt for license details.

# This class is as small and independant as possible as it will get sent to clients for execution.

require 'thread'

module RExec

	# This class represents an abstract connection to another ruby process. The interface does not impose
	# any structure on the way this communication link works, except for the fact you can send and receive
	# objects. You can implement whatever kind of idiom you need for communication on top of this library.
	#
	# Depending on how you set things up, this could connect to a local ruby process, or a remote ruby process
	# via `ssh`.
	#
	# To set up a connection, you need to use {start_server}.
	class Connection
		public

		def self.build(process, options, &block)
			cin = process.input
			cout = process.output
			cerr = process.error

			# We require both cin and cout to be connected in order for connection to work
			raise InvalidConnectionError.new("Input (#{cin}) or Output (#{cout}) is not connected!") unless cin and cout

			yield cin

			cin.puts("\004")

			return self.new(cout, cin, cerr)
		end

		# Create a new connection. You need to supply a pipe for reading input, a pipe for sending output,
		# and optionally a pipe for errors to be read from.
		def initialize(input, output, error = nil)
			@input = input
			@output = output
			@running = true

			@error = error

			@receive_mutex = Mutex.new
			@send_mutex = Mutex.new
		end

		# The pipe used for reading data
		def input
			@input
		end

		# The pipe used for writing data
		def output
			@output
		end

		# The pipe used for receiving errors. On the client side this pipe is writable, on the server 
		# side this pipe is readable. You should avoid using it on the client side and simply use $stderr.
		def error
			@error
		end

		# Stop the connection, and close the output pipe.
		def stop
			if @running
				@running = false
				@output.close
			end
		end

		# Return whether or not the connection is running.
		def running?
			@running
		end

		# This is a very simple runloop. It provides an object when it is received.
		def run(&block)
			while @running
				pipes = IO.select([@input])

				if pipes[0].size > 0
					object = receive_object

					if object == nil
						@running = false
						return
					end

					begin
						yield object
					rescue Exception => ex
						send_object(ex)
					end
				end
			end
		end

		# Dump any text which has been written to $stderr in the child process.
		def dump_errors(to = $stderr)
			if @error and !@error.closed?
				while true
					result = IO.select([@error], [], [], 0)

					break if result == nil

					to.puts @error.readline.chomp
				end
			end
		end

		# Receive an object from the connection. This function is thread-safe. This function may block.
		def receive_object
			object = nil

			@receive_mutex.synchronize do
				begin
					object = Marshal.load(@input)
				rescue EOFError
					object = nil
					@running = false
				end
			end

			if object and object.kind_of?(Exception)
				raise object
			end

			return object
		end

		# Send object(s). This function is thread-safe.
		def send_object(*objects)
			@send_mutex.synchronize do
				objects.each do |o|
					data = Marshal.dump(o)
					@output.write(data)
				end

				@output.flush
			end
		end
	end
end
