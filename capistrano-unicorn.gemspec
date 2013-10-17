# -*- encoding: utf-8 -*-
require File.expand_path("../lib/capistrano-unicorn/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name        = "capistrano-unicorn"
  spec.version     = CapistranoUnicorn::VERSION.dup
  spec.author      = "Dan Sosedoff"
  spec.email       = "dan.sosedoff@gmail.com"
  spec.homepage    = "https://github.com/sosedoff/capistrano-unicorn"
  spec.summary     = %q{Unicorn integration for Capistrano}
  spec.description = %q{Capistrano plugin that integrates Unicorn server tasks.}
  spec.license     = "MIT"

  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_development_dependency "unicorn"
  spec.add_runtime_dependency     "capistrano"
end