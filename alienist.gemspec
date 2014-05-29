# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "alienist/version"

files = `git ls-files -- lib/* spec/*`.split("\n")

Gem::Specification.new do |s|
  s.name        = 'alienist'
  s.version     = Alienist::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = 'Thomas E. Enebo'
  s.email       = 'tom.enebo@gmail.com'
  s.homepage    = 'http://github.com/enebo/alienist'
  s.summary     = %q{Java heap memory analysis tool}
  s.description = %q{Java heap memory analysis tool with polyglot smarts}

  s.files         = files
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ["lib"]
  s.has_rdoc      = true
end
