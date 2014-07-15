require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  desc "Run all unit specs"
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = "spec/**/*_spec.rb"
    t.rspec_opts = <<-SPEC_OPTS \
      --require spec_helper    \
      --format progress        \
      --colour
    SPEC_OPTS
  end
end

task :default => :spec
