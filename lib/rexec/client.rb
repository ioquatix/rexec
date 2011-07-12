# Copyright (c) 2007, 2011 Samuel G. D. Williams. <http://www.oriontransfer.co.nz>
# Released under the MIT license. Please see LICENSE.txt for license details.

# This code is executed in a remote ruby process.

$stdout.sync = true
$stderr.sync = true

# We don't connect to $stderr here as this is a client. Clients write to regular $stderr.
$connection = RExec::Connection.new($stdin, $stdout)

