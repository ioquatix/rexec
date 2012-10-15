#!/usr/bin/env ruby

begin
	sleep 100
rescue Interrupt
	puts "Caught Interrupt"
end