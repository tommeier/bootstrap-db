module Bootstrap
  module Db
    class Adapter
      include Bootstrap::Db::Command

      attr_reader :config

      def initialize(config)
        @config = config
      end

      # implemented by adapters
      def command_string
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


    end
  end
end
