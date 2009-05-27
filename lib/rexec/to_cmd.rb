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
  
  # Open a process. Similar to IO.popen, but provides a much more generic interface to stdin, stdout, 
  # stderr and the pid. We also attempt to tidy up as much as possible given some kind of error or
  # exception. You are expected to write to output, and read from input and error.
  def self.open_process(cmd, &block) # :yields: output, input, error, child_pid
    cin = IO.pipe
    cout = IO.pipe
    cerr = IO.pipe
    
    cid = fork do
      cin[WR].close
      cout[RD].close
      cerr[RD].close
      
      STDIN.reopen(cin[RD])
      STDOUT.reopen(cout[WR])
      STDERR.reopen(cerr[WR])
      
      STDOUT.sync = true if not STDOUT.sync
      STDERR.sync = true if not STDERR.sync
      
      exec(cmd)
      
      # We should never get here, but for completeness:
      return
    end
    
    cin[RD].close
    cout[WR].close
    cerr[WR].close
    
    result = nil
    
    begin
      yield cin[WR], cout[RD], cerr[RD], cid
      close_pipes(cin[WR])

      # Wait for the process to finish
      result ||= Process.wait(cid)
    rescue
      $stderr.puts "Exception: #{$!}"
      close_pipes(cin[WR])
      
      Process.kill("INT", cid)
      result ||= Process.wait(cid)
      
      raise
    ensure
      dump_pipes(cout[RD], cerr[RD])
      close_pipes(cin[WR], cout[RD], cerr[RD])
    end
    
    return result
  end
  
  # Close all the supplied pipes
  def self.close_pipes(*pipes)
    pipes.each do |pipe|
      pipe.close unless pipe.closed?
    end
  end
  
  # Dump any remaining data from the pipes, until they are closed.
  def self.dump_pipes(*pipes)
    pipes.delete_if { |pipe| pipe.closed? }
    # Dump any output that was not consumed (errors, etc)
    while pipes.size > 0
      result = IO.select(pipes)

      result[0].each do |pipe|
        if pipe.closed? || pipe.eof?
          pipes.delete(pipe)
          next
        end

        $stderr.puts "*** [#{pipe.to_i}] " + pipe.readline.chomp
      end
    end
  end
end
