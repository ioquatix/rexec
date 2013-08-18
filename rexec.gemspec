# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rexec/version'

Gem::Specification.new do |spec|
	spec.name          = "rexec"
	spec.version       = RExec::VERSION
	spec.authors       = ["Samuel Williams"]
	spec.email         = ["samuel.williams@oriontransfer.co.nz"]
	spec.description   = <<-EOF
		RExec stands for Remote Execute and provides support for executing processes
		both locally and remotely. It provides a number of different tools to assist
		with running Ruby code, including remote code execution, daemonization, task
		management and priviledge management.
	EOF
	spec.summary       = "RExec assists with and manages the execution of child and daemon tasks."
	spec.homepage      = "http://www.codeotaku.com/projects/rexec"
	spec.license       = "MIT"

	spec.files         = `git ls-files`.split($/)
	spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
	spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ["lib"]

	spec.add_development_dependency "bundler", "~> 1.3"
	spec.add_development_dependency "rake"
	
	spec.add_dependency "rainbow"
end
