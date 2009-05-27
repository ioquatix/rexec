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

class LocalTest < Test::Unit::TestCase
  PIPES_PATH = Pathname.new(__FILE__).dirname + "pipes.rb"
  TEXT = "The quick brown fox jumped over the lazy dog."
  
  def test_remote_execution
    RExec::open_process(PIPES_PATH) do |cin, cout, cerr, pid|
      cin.write(TEXT)
      cin.close
      
      sleep 1
      assert_equal "STDOUT: " + TEXT, cout.read
      assert_equal "STDERR: " + TEXT, cerr.read
    end
  end
  
  def test_remote_ruby
    RExec::open_process("ruby") do |cin, cout, cerr, pid|
      cin.puts(PIPES_PATH.read)
      cin.puts("\004")
      
      cin.write(TEXT)
      cin.close
      
      sleep 1
      assert_equal "STDOUT: " + TEXT, cout.read
      assert_equal "STDERR: " + TEXT, cerr.read
    end
  end
end