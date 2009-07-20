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

$connection.run do |object|
  case(object[0])
  when :bounce
    $stderr.puts("Bouncing #{object[1].inspect}...")
    $connection.send_object(object[1])
  when :exception
    $stderr.puts("Raising exception...")
    raise Exception.new("I love exceptions!")
  when :stop
    $stderr.puts("Stopping connection manually...")
    $connection.stop
  when :stderr
    $stderr.puts object[1]
    $stderr.flush
  end
end
