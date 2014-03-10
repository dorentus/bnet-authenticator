# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require 'bnet/authenticator/version'

Gem::Specification.new do |s|
  s.name       = 'bnet-authenticator'
  s.version     = Bnet::Authenticator::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['ZHANG Yi']
  s.email       = ['zhangyi.cn@gmail.com']
  s.homepage    = 'https://github.com/dorentus/bnet-authenticator'
  s.summary     = %q{Battle.net Mobile Authenticator}
  s.description = %q{Ruby implementation of the Battle.net Mobile Authenticator}
  s.license     = 'MIT'

  s.required_ruby_version = '>= 1.9.3'

  if s.respond_to?(:add_development_dependency)
    s.add_development_dependency 'rake', '~> 10.1'
    s.add_development_dependency 'minitest', '~> 5.0'
    s.add_development_dependency 'yard', '~> 0.8'
    s.add_development_dependency 'coveralls', '~> 0.7'
  end

  s.files         = `git ls-files`.split("\n") - %w(.travis.yml .gitignore)
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end
