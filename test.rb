
class Validator
	class << self
		attr_accessor :config
	end

	def self.setup
		self.config = {}
	end
end


Validator.setup
p Validator.config
