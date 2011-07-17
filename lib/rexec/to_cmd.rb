
class Array
	# Join a sequence of arguments together to form a executable command.
	def to_cmd
		collect{|v| v.to_cmd}.join(' ')
	end
end

class Pathname
	def to_cmd
		to_s.to_cmd
	end
end

class Symbol
	def to_cmd
		to_s.to_cmd
	end
end

class String
	# Conditionally quote a string if it contains whitespace or quotes.
	def to_cmd
		if match(/\s|"|'/)
			self.dump
		else
			self
		end
	end
end
