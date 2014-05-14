# RExec

**This project is stable but no longer maintained and has been superceeded by [process-group][2] and [process-daemon][3]**
RExec stands for Remote Execute and provides support for executing processes both locally and remotely. It provides a number of different tools to assist with running Ruby code:

* A framework to send Ruby code to a remote server for execution.
* A framework for writing command line daemons (i.e. `start`, `restart`, `stop`, `status`).
* A comprehensive `Task` class for launching tasks, managing input and output, exit status, etc.
* Basic privilege management code for changing the processes owner.
* A bunch of helpers for various different things (such as reading a file backwards).
* `daemon-exec` executable for running regular shell tasks in the background.

For more information please see the [project page][1].

[1]: http://www.codeotaku.com/projects/rexec
[2]: https://github.com/ioquatix/process-group
[3]: https://github.com/ioquatix/process-daemon

## Installation

Add this line to your application's Gemfile:

    gem 'rexec'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rexec

## Usage

### Comprehensive process management

`RExec::Task` provides a comprehensive wrapper for low level process execution
and life-cycle management. You can easy spawn new child processes, background
processes and execute Ruby code in a child instance.

### Light weight bi-directional communication

The `RExec::Connection` provides a simple process based API for communicating 
with distant instances of Ruby. These can either be local or remote, such
as over SSH.

### Simple daemonization

The `RExec::Daemon` module provides the foundation to develop long-running
background processes. Simply create a daemon class which inherits from 
`RExec::Daemon::Base` and you can have a fully featured background daemon 
with the standard command line interface, e.g. `start`, `restart`, `status`
and `stop`.

Along with this, a executable is included called `daemon-exec` which allows
for any standard shell script to be run as a background process.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT license.

Copyright, 2012, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
