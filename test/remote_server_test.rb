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

# This script is used to test actual remote connections
# e.g. ./test_remote.rb "ssh haru.oriontransfer.org"

require 'rubygems'

require 'test/unit'
require 'fileutils'
require 'pathname'
require 'rexec'

if $0.match("remote_server_test.rb") and ARGV.size > 0
	COMMAND = ARGV.join(" ")
else
	COMMAND = "ruby"
end

BOUNCE = "Apples and Oranges"

class RemoteServerTest < Test::Unit::TestCase
  def test_block_execution
    code = Pathname.new(__FILE__).dirname + "./client.rb"
    
    RExec::start_server(code.read, COMMAND) do |conn, pid|
      conn.send_object([:bounce, BOUNCE])

      assert_equal BOUNCE, conn.receive_object

      conn.dump_errors

      conn.stop
    end
  end
  
  def test_result_execution
    code = Pathname.new(__FILE__).dirname + "./client.rb"
    
    conn, pid = RExec::start_server(code.read, COMMAND, :passthrough => [])
    
    conn.send_object([:bounce, BOUNCE])
    assert_equal BOUNCE, conn.receive_object
    
    conn.dump_errors

    conn.stop
  end
end
