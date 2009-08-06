require "rubygems"
require "spec/rake/spectask"

$LOAD_PATH.unshift "lib"
require "rack/bug"

begin
  require 'jeweler'

  Jeweler::Tasks.new do |s|
    s.name      = "rack-bug"
    s.author    = "Bryan Helmkamp"
    s.email     = "bryan" + "@" + "brynary.com"
    s.homepage  = "http://github.com/brynary/rack-bug"
    s.summary   = "Debugging toolbar for Rack applications implemented as middleware"
    # s.description  = "TODO"
    s.rubyforge_project = "rack-bug"
    s.extra_rdoc_files = %w(README.rdoc MIT-LICENSE.txt)
  end

  Jeweler::RubyforgeTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
end

desc "Run all specs in spec directory with RCov"
Spec::Rake::SpecTask.new(:rcov) do |t|
  t.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
  t.rcov = true
  t.rcov_opts = lambda do
    IO.readlines(File.dirname(__FILE__) + "/spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
  end
end

task :spec => :check_dependencies

desc "Run the specs"
task :default => :spec