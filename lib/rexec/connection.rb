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

# This class is as small and independant as possible as it will get sent to clients for execution.

require 'thread'

module RExec
  
  # This class represents an abstract connection to another ruby process. The interface does not impose
  # any structure on the way this communication link works, except for the fact you can send and receive
  # objects. You can implement whatever kind of idiom you need for communication on top of this library.
  #
  # Depending on how you set things up, this can connect to a local ruby process, or a remote ruby process
  # via SSH (for example).
  class Connection
    public
    
    # Create a new connection. You need to supply a pipe for reading input, a pipe for sending output,
    # and optionally a pipe for errors to be read from.
    def initialize(input, output, error = nil)
      @input = input
      @output = output
      @running = true

      @error = error

      @receive_mutex = Mutex.new
      @send_mutex = Mutex.new
    end

    # The pipe used for reading data
    def input
      @input
    end

    # The pipe used for writing data
    def output
      @output
    end

    # The pipe used for receiving errors. On the client side this pipe is writable, on the server 
    # side this pipe is readable. You should avoid using it on the client side and simply use $stderr.
    def error
      @error
    end

    # Stop the connection, and close the output pipe.
    def stop
      @running = false
      @output.close
    end
    
    # Return whether or not the connection is running.
    def running?
      @running
    end

    # This is a very simple runloop. It provides an object when it is received.
    def run(&block)
      while @running
        pipes = IO.select([@input])

        if pipes[0].size > 0
          object = receive
          
          if object == nil
            @running = false
            return
          end
          
          begin
            yield object
          rescue Exception => ex
            send(ex)
          end
        end
      end
    end

    # Dump any text which has been written to $stderr in the child process.
    def dump_errors(to = $stderr)
      if @error
        while true
          result = IO.select([@error], [], [], 0)

          break if result == nil

          to.puts @error.readline.chomp
        end
      end
    end
    
    # Receive an object from the connection. This function is thread-safe. This function may block.
    def receive
      object = nil

      @receive_mutex.synchronize do
        begin
          object = Marshal.load(@input)
        rescue EOFError
          object = nil
          @running = false
        end
      end
      
      if object and object.kind_of?(Exception)
        raise object
      end
      
      return object
    end

    # Send object(s). This function is thread-safe.
    def send(*objects)
      @send_mutex.synchronize do
        objects.each do |o|
          data = Marshal.dump(o)
          @output.write(data)
        end
        
        @output.flush
      end
    end
  end
end
