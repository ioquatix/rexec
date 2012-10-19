
Dir.chdir("../") do
	require './lib/rexec/version'

	Gem::Specification.new do |s|
		s.name = "rexec"
		s.version = RExec::VERSION::STRING
		s.author = "Samuel Williams"
		s.email = "samuel@oriontransfer.org"
		s.homepage = "http://www.oriontransfer.co.nz/gems/rexec"
		s.platform = Gem::Platform::RUBY
		s.summary = "RExec assists with and manages the execution of child and daemon tasks."
		s.files = FileList["{bin,lib,test}/**/*"] + ["README.md", "rakefile.rb", "Gemfile"]

		s.executables << 'daemon-exec'

		s.has_rdoc = "yard"
		s.add_dependency "rainbow"

		s.test_files = FileList["test/*_test.rb"]
	end
end
