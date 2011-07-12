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
  
  class InvalidConnectionError < Exception
  end
  
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
  #
  # If <tt>command</tt> is a shell such as "/bin/sh", and we need to start ruby separately, you can supply
  # <tt>options[:ruby] = "/usr/bin/ruby"</tt> to explicitly start the ruby command.
  def self.start_server(code, command, options = {}, &block)
    options[:passthrough] = :err unless options[:passthrough]
    
    send_code = Proc.new do |cin|
      cin.puts(@@connection_code)
      cin.puts(@@client_code)
      cin.puts(code)
    end
    
    if block_given?
      Task.open(command, options) do |process|
        conn = Connection.build(process, options, &send_code)
        
        yield conn, process.pid
      end
    else
      process = Task.open(command, options)
      conn = Connection.build(process, options, &send_code)
      
      return conn, process.pid
    end
  end
end
