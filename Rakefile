require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc "Run tests"

if ENV["TRAVIS"] == "true"
  require 'coveralls/rake/task'
  Coveralls::RakeTask.new

  task :default => [:test, 'coveralls:push']
else
  task :default => :test
end
