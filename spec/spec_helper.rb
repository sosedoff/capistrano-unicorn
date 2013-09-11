require 'capistrano-spec'
require 'capistrano-unicorn'
require 'pry'

RSpec.configure do |config|
  config.include Capistrano::Spec::Matchers
  config.include Capistrano::Spec::Helpers
end
