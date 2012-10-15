#!/usr/bin/env ruby

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

require 'helper'

require 'fileutils'
require 'pathname'
require 'rexec'

class ServerTest < Test::Unit::TestCase
	def test_local_execution
		code = Pathname.new(__FILE__).dirname + "./client.rb"
		sobj = [1, 2, "three", 4]
		stderr_text = "There was no error.. maybe?"
		connection_started = false
		object_received = false

		RExec::start_server(code.read, "ruby", :passthrough => []) do |conn, task|
			connection_started = true
			conn.send_object([:bounce, sobj])

			assert_equal sobj, conn.receive_object

			assert_raises(Exception) do
				conn.send_object([:exception])
				obj = conn.receive_object
        
				puts "Received object which should have been exception: #{obj.inspect}"
			end

			conn.dump_errors
			conn.send_object([:stderr, stderr_text])

			puts "Attemping to read from #{conn.error.to_i}..."
			assert_equal stderr_text, conn.error.readline.chomp

			conn.stop
		end

		assert(connection_started, "Connection started")
	end
  
	def test_shell_execution
		connection_started = false
		code = Pathname.new(__FILE__).dirname + "client.rb"

		test_obj = [1, 2, 3, 4, "five"]

		RExec::start_server(code.read, "/bin/sh -c ruby", :passthrough => []) do |conn, task|
			connection_started = true
			conn.send_object([:bounce, test_obj])

			assert_equal test_obj, conn.receive_object

			conn.stop
		end

		assert(connection_started, "Connection started")
	end
  
	def test_shell_execution_non_block
		connection_started = false
		code = Pathname.new(__FILE__).dirname + "client.rb"

		test_obj = [1, 2, 3, 4, "five"]

		conn, task = RExec::start_server(code.read, "/bin/sh -c ruby", :passthrough => [])
		conn.send_object([:bounce, test_obj])

		assert_equal test_obj, conn.receive_object

		conn.stop
	end
end
