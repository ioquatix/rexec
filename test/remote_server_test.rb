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

# This script is used to test actual remote connections
# e.g. ./test_remote.rb "ssh haru.oriontransfer.org"

require 'rubygems'

require 'test/unit'
require 'fileutils'
require 'pathname'
require 'rexec'

COMMAND = ARGV[1] || "ruby"
BOUNCE = "Apples and Oranges"

class RemoteServerTest < Test::Unit::TestCase
  def test_block_execution
    code = Pathname.new(__FILE__).dirname + "./client.rb"
    
    RExec::start_server(code.read, COMMAND, :passthrough => []) do |conn, pid|
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
