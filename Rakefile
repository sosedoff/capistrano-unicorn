require 'bundler'
require 'bundler/gem_tasks'
require "rspec/core/rake_task"


namespace :test do
  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.pattern = "spec/**/*_spec.rb"
  end
end

task :default => "test:spec"