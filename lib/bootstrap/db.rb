require 'bootstrap/db/version'

module Bootstrap
  module Db
    # Error when unable to find '.bootstrap' file when required
    class MissingSettingsFileError < StandardError; end
  end
end

require 'bootstrap/db/config'
require 'bootstrap/db/railtie'
require 'bootstrap/db/log'
require 'bootstrap/db/command'
require 'bootstrap/db/sandbox'
require 'bootstrap/db/rebase'
require 'bootstrap/db/adapter'
require 'bootstrap/db/adapter/mysql'
require 'bootstrap/db/adapter/postgres'


