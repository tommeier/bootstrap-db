module Bootstrap
  module Db
    class Postgres < Adapter
      LOAD_COMMAND = "pg_restore"

      CONNECTION_PARAMS = [ :username, :password, :host, :port ]
      CONFIG_DEFAULTS = {
        :port => 5423
      }

      # Compile connection string
      def connection_string
        @connection_string ||= begin
          CONNECTION_PARAMS.inject([]) do |result, element|
            config_value = config.settings[element.to_s] || CONFIG_DEFAULTS[element]
            result << "--#{element}='#{config_value}'" if config_value
            result
          end.join(' ')
        end
      end

      def dump!
        #pg_dump --help
        dump_command = [
          "pg_dump",
          "--create --format=c",
          "--file=#{file_path}",
          connection_string
        ]

        if ignore_tables.present?
          ignore_tables.each do |table_name|
            dump_command << "--exclude-table='#{config.settings["database"]}.#{table_name.strip}'"
          end
        end

        if additional_parameters.present?
          additional_parameters.each do |param|
            dump_command << param
          end
        end

        dump_command << config.settings['database']

        display_and_execute(dump_command.join(' '))
      end

      def load!
        #pg_restore --help
        load_command = [
          "pg_restore",
          "--single-transaction --format=c",
          "--dbname='#{config.settings["database"]}'",
          connection_string,
          file_path
        ]

        display_and_execute(load_command.join(' '))
      end

      def rebase!
        load_rebase_functions

        # REDO THIS
        cmd = "SELECT MIN(created_at) FROM CUSTOMERS"
        result = display_and_execute("#{psql_execute} --command='#{cmd}'")
        log(result.inspect)
        #TODO: Make this better!
        start_point = result.scan(/(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}\.\d{6})/).flatten.first


        if time_zone = (ENV['TZ'] || ENV['ZONEBIE_TZ'])
          STDERR.puts "CUSTOM ZONE: #{time_zone}"
          #Handle custom timezones
          Time.zone = time_zone
          new_point = Time.zone.now.to_formatted_s(:db)
        else
          # Default to 'now' in the local timestamp
          new_point = "localtimestamp"
        end

        cmd = "SELECT rebase_db_time('#{start_point}'::timestamp, '#{new_point}'::timestamp);"
        puts cmd
        result = display_and_execute("#{psql_execute} --command=#{cmd.shellescape}")
        puts "RESULT : "
        puts result.inspect

      end

      private

      def psql_execute
        @psql_execute ||= begin
          [
            'psql',
            connection_string,
            "--dbname='#{config.settings['database']}'"
          ].join(' ')
        end
      end

      def load_rebase_functions
        function_sql_path = File.expand_path('../../sql/rebase_time.sql', __FILE__)
        display_and_execute("#{psql_execute} --file='#{function_sql_path}'")
      end

      def default_file_name
        'bootstrap_data.dump' #Custom format 'c'
      end
    end
  end
end
