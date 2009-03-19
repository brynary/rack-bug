require "rubygems"
require "rake/gempackagetask"
require "rake/clean"
require "spec/rake/spectask"

$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'

require "rack/bug"

Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
end

desc "Run the specs"
task :default => :spec

desc "Run all specs in spec directory with RCov"
Spec::Rake::SpecTask.new(:rcov) do |t|
  t.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
  t.rcov = true
  t.rcov_opts = lambda do
    IO.readlines(File.dirname(__FILE__) + "/spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
  end
end

spec = Gem::Specification.new do |s|
  s.name         = "rack-bug"
  s.version      = Rack::Bug::VERSION
  s.author       = "Bryan Helmkamp"
  s.email        = "bryan" + "@" + "brynary.com"
  s.homepage     = "http://github.com/brynary/rack-bug"
  s.summary      = "Debugging toolbar for Rack applications implemented as middleware"
  s.description  = s.summary
  s.files        = %w[History.txt Rakefile README.rdoc] + Dir["lib/**/*"]
  
  # rdoc
  s.has_rdoc         = true
  s.extra_rdoc_files = %w(README.rdoc MIT-LICENSE.txt)
end

Rake::GemPackageTask.new(spec) do |package|
  package.gem_spec = spec
end

desc 'Install the package as a gem.'
task :install => [:clean, :package] do
  gem = Dir['pkg/*.gem'].first
  sh "sudo gem install --no-rdoc --no-ri --local #{gem}"
end