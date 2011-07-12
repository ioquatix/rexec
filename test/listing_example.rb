#!/usr/bin/env ruby

# Copyright (c) 2007, 2009, 2011 Samuel G. D. Williams. <http://www.oriontransfer.co.nz>
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
require 'rexec'

CLIENT = <<EOF

$connection.run do |path|
  listing = []

  IO.popen("ls -la " + path.dump, "r+") do |ls|
    listing = ls.readlines
  end

  $connection.send_object(listing)
end

EOF

command = ARGV[0] || "ruby"

puts "Starting server..."
RExec::start_server(CLIENT, command) do |conn, pid|
  puts "Sending path..."
  conn.send_object("/")

  puts "Waiting for response..."
  listing = conn.receive_object

  puts "Received listing:"
  listing.each do |entry|
    puts "\t#{entry}"
  end
end
