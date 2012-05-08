require 'forgery'

class Zeus::NameGenerator
  def self.generate
    [Forgery::Basic.color, Forgery::Address.street_name.split(" ").first, rand(1000)].join("-").downcase
  end
end