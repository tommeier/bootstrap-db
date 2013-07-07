require 'bootstrap/db/version'

module Bootstrap
  module Db

    def load_config
      file_path = File.join(Rails.root, 'config/database.yml')
      raise "Error - Please ensure your config/database.yml exists" unless File.exists?(file_path)
      YAML::load(ERB.new(IO.read(file_path)).result)
    end

    def raise_common_errors(config)
       raise "Please ensure your config/database.yml file has a host for the database. eg. host = localhost"  if config[RAILS_ENV]["host"].blank?
    end

  end
end

require 'bootstrap/db/railtie'

