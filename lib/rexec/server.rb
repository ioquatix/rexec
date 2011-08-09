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

require 'pathname'
require 'rexec/task'
require 'rexec/connection'

module RExec

	# Indicates that a connection could not be established because the pipes were not available or not connected.
	class InvalidConnectionError < Exception
	end
	
	# The connection code which is sent to the client to be used for bi-directional communication.
	CONNECTION_CODE = (Pathname.new(__FILE__).dirname + "connection.rb").read
	
	# The client code which sets up the connection object and initialises communciation.
	CLIENT_CODE = (Pathname.new(__FILE__).dirname + "client.rb").read
	
	# Start a remote ruby server. This function is a structural cornerstone. This code runs the command you 
	# supply (this command should start an instance of ruby somewhere), sends it the code in
	# +connection.rb+ and +client.rb+ as well as the code you supply.
	#
	# Once the remote ruby instance is set up and ready to go, this code will return (or yield) the connection
	# and pid of the executed command.
	#
	# From this point, you can send and receive objects, and interact with the code you provided within a
	# remote ruby instance.
	#
	# For a local shell, you could specify +"ruby"+ as the command. For a remote shell via SSH, you could specify
	# +"ssh example.com ruby"+.
	# 
	# ==== Example
	# Create a file called +client.rb+ on the server. This file contains code to be executed on the client. This
	# file can assume the existance of an object called +$connection+:
	# 
	# 	$connection.run do |object|
	# 	  case(object[0])
	# 	  when :bounce
	# 	    $connection.send_object(object[1])
	# 	  end
	# 	end
	# 
	# Then, on the server, create a new program +server.rb+ which will be used to coordinate the execution of code:
	#
	# 	shell = "ssh example.com ruby"
	# 	client_code = (Pathname.new(__FILE__).dirname + "./client.rb").read
	# 	
	# 	RExec::start_server(client_code, shell) do |connection, pid|
	# 		connection.send_object([:bounce, "Hello World!"])
	# 		result = connection.receive_object
	# 	end
	#
	def self.start_server(code, command, options = {}, &block)
		options[:passthrough] = :err unless options[:passthrough]

		send_code = Proc.new do |cin|
			unless options[:raw]
				cin.puts(CONNECTION_CODE)
				cin.puts(CLIENT_CODE)
			end
			
			cin.puts(code)
		end

		if block_given?
			Task.open(command, options) do |process|
				conn = Connection.build(process, options, &send_code)

				yield conn, process.pid
				
				conn.stop
			end
		else
			process = Task.open(command, options)
			conn = Connection.build(process, options, &send_code)

			return conn, process.pid
		end
	end
end
