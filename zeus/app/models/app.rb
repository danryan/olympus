class App < ActiveRecord::Base
  
  validates :name, :presence => true, :uniqueness => true
  
  after_initialize :generate_name, :unless => lambda { name.present? }
  
  serialize :env_vars, Hash
  
  def generate_name
    self.name = Zeus::NameGenerator.generate
  end
  
  def url
    "#{name}.#{Zeus::ROOT_URL}"
  end
  
end
