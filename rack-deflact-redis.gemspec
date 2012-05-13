lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'deflect_redis.rb'

Gem::Specification.new do |s|
  s.name        = "rack-deflect-redis"
  s.version     = "0.42"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Marvin Frick"]
  s.email       = ["marv@hostin.is"]
  s.homepage    = "https://github.com/MrMarvin/Rack-DeflectRedis"
  s.summary     = "Rack middleware to counter DoS Attacks by blocking bad requests before they reach your app using Redis as backend"
  s.description = "It could be quite usefull."
  s.required_rubygems_version = ">= 1.3.6"
  s.required_ruby_version = '>= 1.8.7'
  s.add_dependency('redis', '>= 2.2.2')

  s.files        = Dir.glob("{lib}/**/*") + Dir.glob("{test/**/*}") + %w(README.md)
  s.require_path = 'lib'
end
