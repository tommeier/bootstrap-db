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
        pre_dump_prepare!

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

        result
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
        rebase_to   = current_db_time
        rebase_cmd  = "SELECT rebase_db_time('#{rebase_to}'::timestamp);"

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

      def pre_dump_prepare!
        dump_table_commands = File.read(File.expand_path('../../sql/dump_tables.sql', __FILE__))
        rebase_commands     = File.read(File.expand_path('../../sql/rebase_time.sql', __FILE__))

        pre_dump_command = <<-SQL.gsub(/^\s+/,'')
          #{dump_table_commands}
          #{rebase_commands}
          #{frozen_insert_commands}
          #{generated_insert_command}
        SQL

        display_and_execute("#{psql_execute} --command=#{pre_dump_command.shellescape}")
      end

      #Update generated at value for dump
      def generated_insert_command
        insert_command = <<-SQL.gsub(/^\s+/,'')
        INSERT INTO bootstrap_db
          (generated_at, file_path)
        VALUES
          ('#{current_db_time}', '#{file_path}');
        SQL
      end

      # Generate bulk insert statement for any frozen attributes
      def frozen_insert_commands
        frozen_attributes = ::Bootstrap::Db::Rebase.frozen
        return "" unless frozen_attributes
        insert_command = "INSERT INTO bootstrap_icebox (table_name, column_name, frozen_id) VALUES "
        frozen_attributes.each do |table_name, frozen_fields|
          frozen_fields.each do |field_name, frozen_ids|
            frozen_ids.each do |frozen_id|
              insert_command << "('#{table_name}','#{field_name}',#{frozen_id}),"
            end
          end
        end
        "#{insert_command.chop};"
      end
    end
  end
end
