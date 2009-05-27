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
require 'rexec'

CLIENT = <<EOF

$connection.run do |path|
  listing = []

  IO.popen("ls -la " + path.dump, "r+") do |ls|
    listing = ls.readlines
  end

  $connection.send(listing)
end

EOF

command = ARGV[0] || "ruby"

puts "Starting server..."
RExec::start_server(CLIENT, command) do |conn, pid|
  puts "Sending path..."
  conn.send("/")

  puts "Waiting for response..."
  listing = conn.receive

  puts "Received listing:"
  listing.each do |entry|
    puts "\t#{entry}"
  end
end
