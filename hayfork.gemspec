
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "hayfork/version"

Gem::Specification.new do |spec|
  spec.name          = "hayfork"
  spec.version       = Hayfork::VERSION
  spec.authors       = ["Bob Lail"]
  spec.email         = ["bob.lailfamily@gmail.com"]

  spec.summary       = %q{ Full-Text search for ActiveRecord and Postgres }
  spec.description   = %q{ Hayfork generates triggers to maintain a Haystack of all searchable fields that Postgres can index easily and efficiently }
  spec.homepage      = "https://github.com/boblail/hayfork"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 5.2.0", "< 7"

  spec.add_development_dependency "bundler", "~> 2.0.2"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "minitest-reporters-turn_reporter"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "rr"
  spec.add_development_dependency "shoulda-context"
end
