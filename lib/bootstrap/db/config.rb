module Bootstrap
  module Db
    class Config
      DB_CONFIG_PATH = 'config/database.yml'

      def self.load!
        file_path   = File.join(Rails.root, DB_CONFIG_PATH)

        unless File.exists?(file_path)
          raise "Error - Please ensure your '#{DB_CONFIG_PATH}' exists"
        end

        config = YAML::load(ERB.new(IO.read(file_path)).result)

        unless config[Rails.env]["host"]
          raise "Please ensure your '#{DB_CONFIG_PATH}' file has a host for the database. eg. host = localhost"
        end

        config
      end
    end
  end
end