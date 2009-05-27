#!/usr/bin/env ruby

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

require 'rubygems'
require 'pathname'
require 'xmlrpc/client'
require 'test/unit'

class LocalTest < Test::Unit::TestCase
  DAEMON = Pathname.new(__FILE__).dirname + "daemon.rb"
  def setup
    system(DAEMON, "start")
    @rpc = XMLRPC::Client.new_from_uri("https://localhost:11235")
  end

  def teardown
    system(DAEMON, "stop")
  end

  def test_connection
    @rpc.call("add", 10)
    total = @rpc.call("total")
    
    assert_equal total, 10
  end
end
