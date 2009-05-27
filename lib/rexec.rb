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

# = Summary =
# This gem provides a very simple connection based API for communicating 
# with remote instances of ruby. These can either be local, or remote, such
# as over SSH.
#
# The API is very simple and deals with sending and receiving objects using 
# Marshal. One of the primary goals was to impose as little structure as
# possible on the end user of this library, while still maintaining a level
# of convenience.
#
# Author::    Samuel Williams (samuel AT oriontransfer DOT org)
# Copyright:: Copyright (c) 2009 Samuel Williams.
# License::   Released under the GNU GPLv3.

require 'rexec/version'
require 'rexec/connection'
require 'rexec/to_cmd'
require 'rexec/server'