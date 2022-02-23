# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fastly_nsq/version"

Gem::Specification.new do |gem|
  gem.name = "fastly_nsq"
  gem.version = FastlyNsq::VERSION
  gem.summary = "Fastly NSQ Adapter"
  gem.description = "Helper classes for Fastly's NSQ Services"
  gem.license = "MIT"
  gem.authors = ["Tommy O'Neil", "Adarsh Pandit", "Joshua Wehner", "Lukas Eklund", "Josh Lane", "Hassan Shahid"]
  gem.email = "tommy@fastly.com"
  gem.homepage = "https://github.com/fastly/fastly_nsq"

  gem.files = `git ls-files`.split("\n")

  gem.executables = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files = gem.files.grep(%r{^(test|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "awesome_print", "~> 1.6"
  gem.add_development_dependency "bundler"
  gem.add_development_dependency "dotenv"
  gem.add_development_dependency "pry-byebug", "~> 3.3"
  gem.add_development_dependency "rspec", "~> 3.4"
  gem.add_development_dependency "rspec-eventually", "0.2"
  gem.add_development_dependency "timecop"
  gem.add_development_dependency "webmock", "~> 3.0"
  gem.add_development_dependency "yard"

  gem.add_dependency "concurrent-ruby", "~> 1.0"
  gem.add_dependency "nsq-ruby", "~> 2.3"
  gem.add_dependency "priority_queue_cxx", "~> 0.3"
end
