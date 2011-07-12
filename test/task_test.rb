#!/usr/bin/env ruby

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

require 'rubygems'

require 'test/unit'
require 'fileutils'
require 'pathname'
require 'rexec'

require 'timeout'

class TaskTest < Test::Unit::TestCase
  TASK_PATH = Pathname.new(__FILE__).dirname + "./task.rb"
  TEXT = "The quick brown fox jumped over the lazy dog."
  STDOUT_TEXT = "STDOUT: " + TEXT
  STDERR_TEXT = "STDERR: " + TEXT
  
  def test_script_execution
    RExec::Task.open(TASK_PATH) do |task|
      task.input.puts(TEXT)
      task.input.close
      
      assert_equal STDOUT_TEXT, task.output.readline.chomp
      assert_equal STDERR_TEXT, task.error.readline.chomp
    end
  end
  
  def test_ruby_execution
    RExec::Task.open("ruby") do |task|
      task.input.puts(TASK_PATH.read)
      task.input.puts("\004")
      
      task.input.puts(TEXT)
      task.input.close
      
      assert_equal STDOUT_TEXT, task.output.readline.chomp
      assert_equal STDERR_TEXT, task.error.readline.chomp
    end
  end
  
  def test_spawn_child
    rd, wr = IO.pipe
    pid = RExec::Task.spawn_child do
      rd.close
      wr.write(TEXT)
      wr.close
      exit(10)
    end
    
    wr.close
    
    pid, status = Process.wait2(pid)
    
    assert_equal rd.read, TEXT
    assert_equal status, status
  end
  
  def test_spawn_daemon
    rd, wr = IO.pipe
    
    # We launch one daemon to start another. The first daemon will exit, but the second will keep on running.
    ppid = RExec::Task.spawn_daemon do
      RExec::Task.spawn_daemon do
        rd.close
        sleep 0.5
        wr.puts(TEXT, Process.pid)
        wr.close
        sleep 0.5
      end
    end
    
    wr.close
    
    Timeout::timeout(5) do
      until !RExec::Task.running?(ppid) do
        sleep(0.1)
      end
      
      text = rd.readline.chomp
      pid = rd.readline.chomp.to_i
      
      assert_raises(EOFError) do
        rd.readline
      end
      
      assert_equal text, TEXT
      assert RExec::Task.running?(pid)
      
      until !RExec::Task.running?(pid) do
        sleep(0.1)
      end
    end
  end
  
  def test_task
    test_results = Proc.new do |input, output, error|
      input.puts TEXT
      input.flush
      
      assert_equal output.readline.chomp, STDOUT_TEXT
      assert_equal error.readline.chomp, STDERR_TEXT
    end
    
    RExec::Task.open(TASK_PATH) do |task|
      test_results.call(task.input, task.output, task.error)
    end
    
    rd, wr = IO.pipe
    
    RExec::Task.open(TASK_PATH, :in => rd) do |task|
      test_results.call(wr, task.output, task.error)
    end
    
    assert rd.closed?
    
    assert_raises(Errno::EINVAL) do
      wr.puts "The pipe is closed on the other side.."
    end
    
    in_rd, in_wr = IO.pipe
    out_rd, out_wr = IO.pipe
    err_rd, err_wr = IO.pipe
    
    spawn_child_daemon = Proc.new do
      task = RExec::Task.open(TASK_PATH, :in => in_rd, :out => out_wr, :err => err_wr, :daemonize => true)
    end
    
    task = RExec::Task.open(spawn_child_daemon, :daemonize => true)
    
    until !task.running? do
      sleep 0.1
    end
    
    test_results.call(in_wr, out_rd, err_rd)
    
    assert !task.running?
  end
  
  def test_task_passthrough
    script = "echo " + "Hello World!".dump + " | #{TASK_PATH.realpath.to_s.dump}"
    
    RExec::Task.open(script, :passthrough => :all) do
      
    end

    [$stdin, $stdout, $stderr].each do |io|
      assert !io.closed?
    end
  end
end
