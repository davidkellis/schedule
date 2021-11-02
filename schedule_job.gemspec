require_relative "lib/schedule_job/version"

Gem::Specification.new do |spec|
  spec.name          = "schedule_job"
  spec.version       = ScheduleJob::VERSION
  spec.authors       = ["David Ellis"]
  spec.email         = ["david@conquerthelawn.com"]

  spec.summary       = "job scheduler"
  spec.description   = "job scheduler"
  spec.homepage      = "https://github.com/davidkellis/scheduler"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.files = Dir["**/**"].
                grep_v(/.gem$/).
                grep_v(%r{\A(?:test|spec|features)/})
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rspec"

  spec.add_dependency "citrus"
  spec.add_dependency "cronex"
  spec.add_dependency "parse-cron"
  spec.add_dependency "activesupport"
end
