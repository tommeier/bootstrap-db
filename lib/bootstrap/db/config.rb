module Bootstrap
  module Db
    class Config
      DB_CONFIG_PATH = 'config/database.yml'

      attr_accessor :settings, :adapter, :dump_name, :dump_path, :dump_dir

      def initialize(loaded_settings)
        self.settings = loaded_settings[Rails.env]
        self.adapter  = self.settings["adapter"].to_sym

        self.dump_path = ENV['FILE'] || File.join(default_dump_path, ENV['FILE_NAME'] || default_dump_name)
        self.dump_name = File.basename(self.dump_path)
        self.dump_dir  = File.dirname(self.dump_path)
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

        def default_dump_path
          @default_dump_path ||= File.join(Rails.root, 'db', 'bootstrap')
        end

        def default_dump_name
          @default_dump_name ||= case self.adapter
          when :postgresql
            'bootstrap_data.dump' #Custom format 'c'
          else
            'bootstrap_data.sql' #MySQL
          end
        end
    end
  end
end
