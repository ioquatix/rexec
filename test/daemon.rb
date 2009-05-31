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

require 'rexec'
require 'rexec/daemon'

require 'webrick'
require 'webrick/https'
require 'xmlrpc/server'

# Very simple XMLRPC daemon
class TestDaemon < RExec::Daemon::Base
  @@var_directory = "/tmp/ruby-test/var"
  
  def self.run
    puts "Starting server..."
    
    @@rpc_server = WEBrick::HTTPServer.new(
      :Port => 11235,
      :BindAddress => "0.0.0.0",
      :SSLEnable => true,
      :SSLVerifyClient => OpenSSL::SSL::VERIFY_NONE,
      :SSLCertName => [["CN", WEBrick::Utils::getservername]])
    
    @@listener = XMLRPC::WEBrickServlet.new
    
    @@listener.add_handler("add") do |amount|
      @@count ||= 0
      @@count += amount
    end
    
    @@listener.add_handler("total") do
      @@count
    end
    
    @@rpc_server.mount("/RPC2", @@listener)
    
    @@rpc_server.start
  end
  
  def self.shutdown
    @@rpc_server.shutdown
  end
end

TestDaemon.daemonize
