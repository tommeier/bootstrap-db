module Bootstrap
  module Db
    class Mysql < Adapter
      # Config -> command line parameter
      CONNECTION_MAP = {
        :username => :u,
        :password => :p,
        :host     => :h
      }

      # Compile connection string
      def connection_string
        @connection_string ||= begin
          CONNECTION_MAP.inject([]) do |result, (config_name, command_name)|
            config_value = config.settings[config_name.to_s]
            result << "-#{command_name} '#{config_value}'" if config_value
            result
          end.join(' ')
        end
      end

      def dump!
        #mysqldump --help
        dump_command = [
          "mysqldump",
          "-q --add-drop-table --add-locks",
          "--extended-insert --lock-tables",
          "--single-transaction",
          connection_string
        ]

        if ignore_tables.present?
          ignore_tables.each do |table_name|
            dump_command << "--ignore-table='#{config.settings["database"]}.#{table_name.strip}'"
          end
        end

        if additional_parameters.present?
          additional_parameters.each do |param|
            dump_command << param
          end
        end

        dump_command << "#{config.settings['database']} > #{config.dump_path}"

        display_and_execute(dump_command.join(' '))
      end

      def load!

      end

      private
    end
  end
end
