Gem::Specification.new do |spec|
  spec.name          = "schedule"
  spec.version       = "1.0.0"
  spec.authors       = ["David Ellis"]
  spec.email         = ["david@conquerthelawn.com"]

  spec.summary       = "job scheduler"
  spec.description   = "job scheduler"
  spec.homepage      = "https://github.com/davidkellis/scheduler"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.files = Dir["**/**"].
                grep_v(/.gem$/).
                grep_v(%r{\A(?:test|spec|features)/})
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
