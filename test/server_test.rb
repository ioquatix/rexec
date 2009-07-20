#!/usr/bin/env ruby

# Copyright (c) 2007 Samuel Williams. Released under the GNU GPLv3.
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

require 'rubygems'

require 'test/unit'
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

    RExec::start_server(code.read, "ruby", :passthrough => []) do |conn, pid|
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

    RExec::start_server(code.read, "/bin/sh -c ruby", :passthrough => []) do |conn, pid|
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

    conn, pid = RExec::start_server(code.read, "/bin/sh -c ruby", :passthrough => [])
    conn.send_object([:bounce, test_obj])

    assert_equal test_obj, conn.receive_object

    conn.stop
  end
end
