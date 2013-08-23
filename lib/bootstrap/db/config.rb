module Bootstrap
  module Db
    class Config
      DB_CONFIG_PATH = 'config/database.yml'

      attr_accessor :settings, :adapter, :bootstrap_dir

      def initialize(loaded_settings)
        self.settings = loaded_settings[Rails.env]
        self.adapter  = self.settings["adapter"].to_sym

        self.bootstrap_dir = ENV['BOOTSTRAP_DIR'] || default_directory

        ensure_bootstrap_dir_exists!
      end

      def self.load!(configuration_path = File.join(Rails.root, DB_CONFIG_PATH))
        unless File.exists?(configuration_path)
          raise "Error - Please ensure your '#{File.basename(configuration_path)}' exists"
        end

        config = YAML::load(ERB.new(IO.read(configuration_path)).result)

        unless config[Rails.env]["host"]
          raise "Please ensure your '#{File.basename(configuration_path)}' file has a host for the database. eg. host = localhost"
        end

        new(config)
      end

      private

        def default_directory
          @default_directory ||= File.join(Rails.root, 'db', 'bootstrap')
        end

        def ensure_bootstrap_dir_exists!
          #Create directories if they don't exist
          Dir.mkdir bootstrap_dir unless File.exists?(bootstrap_dir)
        end
    end
  end
end
