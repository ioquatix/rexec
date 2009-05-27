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

require 'pathname'
require 'rexec/to_cmd'
require 'rexec/connection'

module RExec
  
  @@connection_code = (Pathname.new(__FILE__).dirname + "connection.rb").read
  @@client_code = (Pathname.new(__FILE__).dirname + "client.rb").read
  
  # Start a remote ruby server. This function is a structural cornerstone. This code runs the command you 
  # supply (this command should start an instance of ruby somewhere), sends it the code in
  # <tt>connection.rb</tt> and <tt>client.rb</tt> as well as the code you supply.
  #
  # Once the remote ruby instance is set up and ready to go, this code will return (or yield) the connection
  # and pid of the executed command.
  #
  # From this point, you can send and receive objects, and interact with the code you provided within a
  # remote ruby instance.
  def self.start_server(code, command = "ruby", &block)
    # Child Input, Child Output, Child Error, Process ID
    open_process(command) do |cin, cout, cerr, pid|
      cin.puts(@@connection_code)
      cin.puts(@@client_code)
      cin.puts(code)
      cin.puts("\004")

      conn = Connection.new(cout, cin, cerr)
      
      if block_given?
        yield conn, pid
      else
        return conn, pid
      end
    end
  end
  
end