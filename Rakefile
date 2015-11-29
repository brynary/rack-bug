#!/usr/bin/env rake
require "rubygems"
require "bundler/setup"
require "bundler/gem_tasks"

require "rake"

require "rspec/core"
require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList["spec/**/*_spec.rb"]
end

require "reek/rake/task"
Reek::Rake::Task.new do |t|
  t.fail_on_error = true
  t.verbose = false
  t.source_files = "lib/**/*.rb"
end

require "roodi"
require "roodi_task"
RoodiTask.new do |t|
  t.verbose = false
end

require "wwtd/tasks"
task :default => :spec
task :local => "wwtd:local"

Bundler::GemHelper.install_tasks
