
class Array
	# Join a sequence of arguments together to form a executable command.
	def to_cmd
		collect{|v| v.to_cmd}.join(' ')
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
