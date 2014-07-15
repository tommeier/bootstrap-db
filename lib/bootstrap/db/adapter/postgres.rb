require 'yaml'

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

        result = display_and_execute(dump_command.join(' '))

        save_generated_time!

        result
      end

      def load_rebase_functions!
        function_sql_path = File.expand_path('../../sql/rebase_time.sql', __FILE__)
        display_and_execute("#{psql_execute} --file='#{function_sql_path}'")
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
        generated_time = load_generated_time!

        load_rebase_functions!

        start_point = generated_time
        rebase_to   = current_db_time

        rebase_cmd = "SELECT rebase_db_time('#{start_point}'::timestamp, '#{rebase_to}'::timestamp);"
        display_and_execute("#{psql_execute} --command=#{rebase_cmd.shellescape}")
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

      def default_file_name
        'bootstrap_data.dump' #Custom format 'c'
      end

      def load_generated_time!
        settings = current_settings

        generated_times = settings[:generated_on]
        generated_time = generated_times && generated_times[file_path]

        unless generated_time
          error_message =<<-ERR
          Error - Cannot find generated time. Please recreate dump.
          A generated time is required to know how to rebase time correctly.
          Looking in: #{settings_path}
          ERR
          raise MissingSettingsFileError.new(error_message)
        end

        generated_time
      end

      # Save and track generated time of bootstrap
      def save_generated_time!
        settings = current_settings
        settings[:generated_on] ||= {}

        #Clear any bootstraps that may have been removed
        settings[:generated_on].each do |file, generated_time|
          settings[:generated_on].delete(file) unless File.exists?(file)
        end

        #Set current bootstrap generated time
        settings[:generated_on][file_path] = current_db_time

        #Save settings file
        File.open(settings_path, "w") do |file|
          file.write settings.to_yaml
        end
      end

      def current_settings
        return {} unless File.exists?(settings_path)
        YAML::load_file(settings_path) || {}
      end

      def settings_path
        @settings_path ||= File.expand_path(File.join(config.bootstrap_dir, '.bootstrap'))
      end
    end
  end
end
