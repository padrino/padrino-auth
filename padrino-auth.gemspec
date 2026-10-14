#!/usr/bin/env gem build
# encoding: utf-8

require File.expand_path("../lib/padrino-auth/version.rb", __FILE__)

Gem::Specification.new do |s|
  s.name = "padrino-auth"
  s.authors = ["Igor Bochkariov"]
  s.email = "ujifgc@gmail.com"
  s.summary = "Authentication and authorization modules for Padrino"
  s.homepage = "https://github.com/ujifgc/padrino-auth"
  s.description = "Lean authorization and authentication modules for Padrino framework"
  s.required_ruby_version = ">= 2.7.8"
  s.required_rubygems_version = ">= 1.3.6"
  s.version = Padrino::Auth.version
  s.date = Time.now.strftime("%Y-%m-%d")
  s.license = "MIT"

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
  s.rdoc_options  = ["--charset=UTF-8"]

  s.add_dependency('padrino-core', '>= 0.16')
  s.add_dependency('padrino-helpers', '>= 0.16')

  s.add_development_dependency('minitest', '>= 5')
  s.add_development_dependency('rack-test', '>= 0.5')
  s.add_development_dependency('rake')
  s.add_development_dependency('slim')
end
