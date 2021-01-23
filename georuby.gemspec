# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'geo_ruby/version'

Gem::Specification.new do |s|
  s.name    = 'georuby'
  s.version = GeoRuby::VERSION

  s.summary = 'Ruby data holder for OGC Simple Features'
  s.description = "GeoRuby provides geometric data types from the OGC 'Simple Features' specification."
  s.homepage = 'http://github.com/geekdaily/georuby'
  s.license = 'MIT'

  s.authors = ['Guilhem Vellut', 'Marcos Piccinini', 'Marcus Mateus', 'Doug Cole', 'Jim Meyer']
  s.email = ['jim@geekdaily.org', 'x@nofxx.com']

  # s.extensions = ["ext/georuby/extconf.rb"]
  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  
  s.add_development_dependency "bundler"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "simplecov"
  s.add_development_dependency 'dbf'
  s.add_development_dependency 'json'
  s.add_development_dependency 'nokogiri'

  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'guard-rubocop'
  
  if ENV['CI']
    s.add_development_dependency 'coveralls', require: false
  end
end
