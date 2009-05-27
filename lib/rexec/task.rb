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

class String
  # Helper for turning a string into a shell argument
  def to_cmd
    match(/\s/) ? dump : self
  end
end

class Array
  # Helper for turning an array of items into a command line string
  # <tt>["ls", "-la", "/My Path"].to_cmd => "ls -la \"/My Path\""</tt>
  def to_cmd
    collect{ |a| a.to_cmd }.join(" ")
  end
end

module RExec
  RD = 0
  WR = 1
  
  class Task
    private
    def self.pipes_for_options(options)
      pipes = [nil, nil, nil]
      passthrough_pipes = [$stdin, $stdout, $stderr]

      passthrough = options[:passthrough] || []

      {:in => 0, :out => 1, :err => 2}.each do |key, idx|
        if (passthrough.kind_of?(Symbol) and (passthrough == :all or passthrough == key)) \
          or (passthrough.respond_to?(:include?) and passthrough.include?(key))
          pipes[idx] = nil
        else
          pipes[idx] = IO.pipe
        end
      end

      return pipes
    end
    
    # Close all the supplied pipes
    def close_pipes(*pipes)
      pipes.compact!

      pipes.each do |pipe|
        pipe.close unless pipe.closed?
      end
    end

    # Dump any remaining data from the pipes, until they are closed.
    def dump_pipes(*pipes)
      pipes.compact!

      pipes.delete_if { |pipe| pipe.closed? }
      # Dump any output that was not consumed (errors, etc)
      while pipes.size > 0
        result = IO.select(pipes)

        result[0].each do |pipe|
          if pipe.closed? || pipe.eof?
            pipes.delete(pipe)
            next
          end

          $stderr.puts pipe.readline.chomp
        end
      end
    end
    
    public
    # Open a process. Similar to IO.popen, but provides a much more generic interface to stdin, stdout, 
    # stderr and the pid. We also attempt to tidy up as much as possible given some kind of error or
    # exception. You are expected to write to output, and read from input and error.
    def self.open(command, options = {}, &block)
      cin, cout, cerr = pipes_for_options(options)
      
      # Another option for another day
      # daemonize = options.delete(:daemon)

      cid = fork do
        if cin
          cin[WR].close
          STDIN.reopen(cin[RD])
        end

        if cout
          cout[RD].close
          STDOUT.reopen(cout[WR])
        end

        if cerr
          cerr[RD].close if cerr
          STDERR.reopen(cerr[WR])
        end

        exec(command)

        # We should never get here, but for completeness:
        return
      end

      cin[RD].close if cin
      cout[WR].close if cout
      cerr[WR].close if cerr

      process = Task.new((cin ? cin[WR] : nil), (cout ? cout[RD] : nil), (cerr ? cerr[RD] : nil), cid)

      if block_given?
        begin
          yield process
          process.close_input
          return process.wait
        ensure
          process.stop
        end
      else
        return process
      end
    end
    
    def initialize(input, output, error, pid)
      @input = input
      @output = output
      @error = error
      
      @pid = pid
      @result = nil
    end
    
    attr :input
    attr :output
    attr :error
    attr :pid
    attr :result
    
    # Close all connections to the child process
    def close
      close_pipes(@input, @output, @error)
    end
    
    # Close input pipe to child process (if applicable)
    def close_input
      @input.close if @input and !@input.closed?
    end
    
    # Send a signal to the child process
    def kill(signal = "INT")
      Process.kill("INT", @pid)
    end
    
    # Wait for the child process to finish, return the exit status.
    def wait
      begin
        close_input
        
        @result = Process.wait(@pid)
        
        dump_pipes(@output, @error)
      ensure
        close_pipes(@input, @output, @error)
      end
      
      return @result
    end
    
    # Forcefully stop the child process.
    def stop
      # The process has already been stoped/waited upon
      return if @result
      
      begin
        close_input
        kill
        wait
        
        dump_pipes(@output, @error)
      ensure
        close_pipes(@output, @error)
      end
    end
  end
end
