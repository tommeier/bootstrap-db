ENV["RAILS_ENV"]  ||= 'test'
ENV["RAILS_ROOT"] ||= File.expand_path("../dummy", __FILE__)

# Load Dummy app
require File.expand_path("../dummy/config/environment", __FILE__)

require 'bootstrap-db'
require 'rspec/rails'
require 'database_cleaner'

Rails.backtrace_cleaner.remove_silencers!
ActiveRecord::Migration.maintain_test_schema!

DatabaseCleaner.clean_with :truncation
DatabaseCleaner.strategy = :transaction

RSpec.configure do |config|
  config.mock_with :rspec
  config.run_all_when_everything_filtered = true
  config.order = 'random'
  config.warnings = false

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.clean
  end
end
