#!/usr/bin/env gem build
# encoding: utf-8

require File.expand_path("../lib/padrino-auth/version.rb", __FILE__)

Gem::Specification.new do |s|
  s.name = "padrino-auth"
  s.rubyforge_project = "padrino-auth"
  s.authors = ["Igor Bochkariov"]
  s.email = "ujifgc@gmail.com"
  s.summary = "Authentication and authorization modules for Padrino"
  s.homepage = "https://github.com/ujifgc/padrino-auth"
  s.description = "Lean authorization and authentication modules for Padrino framework"
  s.required_rubygems_version = ">= 1.3.6"
  s.version = Padrino::Auth.version
  s.date = Time.now.strftime("%Y-%m-%d")
  s.license = "MIT"

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
  s.rdoc_options  = ["--charset=UTF-8"]

  s.add_development_dependency('rake', '~> 10')
  s.add_development_dependency('rack', '~> 1')
  s.add_development_dependency('rack-test', '~> 0', '>= 0.5')
  s.add_development_dependency('slim', '~> 2')
  s.add_development_dependency('padrino-helpers', '~> 0.12')
  s.add_development_dependency('padrino-core', '~> 0.12')
end
