# -*- encoding: utf-8 -*-
require File.expand_path('../lib/apollo/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Dan Ryan"]
  gem.email         = ["scriptfu@gmail.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "apollo"
  gem.require_paths = ["lib"]
  gem.version       = Apollo::VERSION
  
  gem.add_dependency "celluloid", ">= 0.9.0"
  gem.add_dependency "active_attr", ">= 0.5.0"
  gem.add_dependency "cabin", "0.4.3"
end
