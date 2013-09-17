module Bootstrap
  module Db
    class Adapter
      include Bootstrap::Db::Command

      attr_reader :config, :file_name, :file_path

      def initialize(config)
        @config = config

        @file_name = ENV['FILE_NAME'] || default_file_name
        @file_path = File.expand_path(File.join(config.bootstrap_dir, file_name))
      end

      # implemented by adapters
      def command_string
        raise NotImplementedError
      end

      # implemented by adapters
      def default_file_name
        raise NotImplementedError
      end

      def ignore_tables
        @ignore_tables ||= begin
          ENV['IGNORE_TABLES'].split(',') if ENV['IGNORE_TABLES']
        end
      end

      def additional_parameters
        @optional_parameters ||= begin
          ENV['ADDITIONAL_PARAMS'].split(',') if ENV['ADDITIONAL_PARAMS']
        end
      end

      def current_db_time
        if Time.respond_to?(:zone) &&
           (time_zone = (ENV['TZ'] || ENV['ZONEBIE_TZ'] || Time.zone))
          Time.zone = time_zone
          Time.zone.now
        else
          Time.now
        end.to_formatted_s(:db)
      end
    end
  end
end
