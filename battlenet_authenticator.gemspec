# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require 'bna/version'

Gem::Specification.new do |s|
  s.name       = "battlenet_authenticator"
  s.version     = Bna::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["ZHANG Yi"]
  s.email       = ["zhangyi.cn@gmail.com"]
  s.homepage    = "https://github.com/dorentus/battlenet_authenticator"
  s.summary     = %q{Battle.net Mobile Authenticator}
  s.description = %q{Ruby implementation of the Battle.net Mobile Authenticator}
  s.license     = 'MIT'

  s.required_ruby_version = '>= 2.0.0'

  if s.respond_to?(:add_development_dependency)
    s.add_development_dependency 'rake', '~> 0'
  end

  s.files         = `git ls-files`.split("\n") - %w(.travis.yml .gitignore)
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
