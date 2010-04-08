
module RExec
	# Updates the global ENV for the duration of block. Not multi-thread safe.
	def self.env (new_env = nil, &block)
	  old_env = ENV.to_hash

	  ENV.update(new_env) if new_env

	  yield

	  ENV.clear
	  ENV.update(old_env)
	end
end