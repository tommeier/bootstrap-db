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

        remove_old_bootstrap_settings!
        save_metadata!
        save_frozen!
        save_post_processing!

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
        set_time_zone!
        load_rebase_functions!

        generated_time       = load_generated_time!
        rebase_to            = current_time.to_s(:db)
        metadata             = bootstrap_settings[:metadata] || {}
        generated_utc_offset = metadata[:generated_utc_offset]
        local_offset         = Time.zone.now.utc_offset

        STDOUT.puts "> local_offset           : #{local_offset}"
        STDOUT.puts "> generated_utc_offset   : #{generated_utc_offset}"
        STDOUT.puts "> current_time           : #{current_time}"
        STDOUT.puts "> generated_time         : #{generated_time}"

        # Database was generated in a different time zone
        # to one being loaded into.
        # Rebase must factor in offset differential for accurate values
        unless generated_utc_offset == local_offset
          generated_time = Time.zone.parse(generated_time)

          if generated_time > current_time
            # Reset to current time with difference removed
            generated_time = current_time - (generated_time - current_time).seconds
          end

          if generated_utc_offset > local_offset
            # Remove the time zone differential
            generated_time = generated_time - (generated_utc_offset.abs + local_offset.abs).seconds #(31st Dec + 1st Jan) .parse
            STDOUT.puts ">> WITHIN generated_utc_offset > local_offset"
            if local_offset < 0 && generated_utc_offset < 0 then
              STDOUT.puts "+-> BOTH ARE LESS THAN 0"
              # Test here
              generated_time = generated_time - (generated_utc_offset.abs + local_offset.abs).seconds #(31st Dec + 1st Jan) .parse
            elsif local_offset > 0 && generated_utc_offset > 0 then
              STDOUT.puts "+-> BOTH ARE GREATER THAN 0"
              generated_time = generated_time - (generated_utc_offset.abs + local_offset.abs).seconds #(31st Dec + 1st Jan) .parse
            else
              STDOUT.puts "+-> ONE IS DIFFERENT"
              generated_time = generated_time - (generated_utc_offset.abs + local_offset.abs).seconds #(1st Jan 2nd jan)
            end
          else #generated_utc_offset < local_offset
            STDOUT.puts ">> WITHIN generated_utc_offset < local_offset"
            if generated_time > current_time
              STDOUT.puts ">>>> generated_time > current_time"
            else
              STDOUT.puts ">>>> generated_time < current_time"
            end

            if local_offset < 0 && generated_utc_offset < 0 then
              STDOUT.puts "+-> BOTH ARE LESS THAN 0"
            elsif local_offset > 0 && generated_utc_offset > 0 then
              STDOUT.puts "+-> BOTH ARE GREATER THAN 0"
            else
              STDOUT.puts "+-> ONE IS DIFFERENT"
              generated_time = generated_time + (generated_utc_offset.abs + local_offset.abs).seconds #(1st Jan 2nd jan)
            end
          end
          generated_time = generated_time.to_s(:db)
        else
          STDOUT.puts "FUCK TIME ZONES"
        end

        rebase_cmd = "SELECT rebase_db_time('#{generated_time}'::TIMESTAMP, '#{rebase_to}'::TIMESTAMP);"
        display_and_execute("#{psql_execute} --command=#{rebase_cmd.shellescape}")

        run_post_rebase_commands!
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

      def load_rebase_functions!
        function_sql_path = File.expand_path('../../sql/rebase_time.sql', __FILE__)
        display_and_execute("#{psql_execute} --file='#{function_sql_path}'")
      end

      def default_file_name
        'bootstrap_data.dump' #Custom format 'c'
      end

      def load_generated_time!
        metadata = bootstrap_settings[:metadata] || {}
        generated_time = metadata[:generated_on]
        unless generated_time
          error_message =<<-ERR
          Error - Cannot find generated time. Please recreate dump.
            A generated time is required to know how to rebase time correctly.
            Looking in: #{settings_path} for #{file_path}
            ERR
          raise MissingSettingsFileError.new(error_message)
        end

        generated_time
      end

      def run_post_rebase_commands!
        # Load frozen or eval post process commands and calculate
        # TODO: Only fire command once (compile command if spike proven)
        frozen = bootstrap_settings[:frozen]
        unless frozen.empty?
          frozen_command = frozen_update_commands(frozen)
          log "Frozen attributes command: #{frozen_command}"
          display_and_execute("#{psql_execute} --command=#{frozen_command.shellescape}")
        end

        post_process = bootstrap_settings[:post_processing]
        unless post_process.empty?
          post_process_command = post_process_commands(post_process)
          log "Running post process commands"
          log "post_process: #{post_process_command.inspect}"
          log post_process_command
          display_and_execute("#{psql_execute} --command=#{post_process_command.shellescape}")
        end
      end

      def post_process_commands(post_process_attributes)
        # { table_name => {
        #     field_name => {
        #       value => ids,
        #       'some value' => [1,2,4,5]
        #     }
        # }
        update_command = ""
        post_process_attributes.each do |table_name, process_fields|
          table_command = " UPDATE #{table_name} SET"
          process_fields.each do |field_name, assignments|
            assignments.each do |value, ids|
              eval_value = Bootstrap::Db::Sandbox.run(value)
              #.to_formatted_s(:db)
              update_command << "#{table_command} #{field_name} = '#{eval_value}' WHERE id IN (#{ids.join(',')});"
            end
          end
        end
        "#{update_command.chop};"
      end

      def frozen_update_commands(frozen_attributes)
        # { table_name => {
        #     field_name => {
        #       ids => [1,3,4,5],
        #       value => 'Something'
        #     }
        # }
        # TODO: make frozen track objects instead of ids, then just send on the field, and has access to id
        update_command = ""
        frozen_attributes.each do |table_name, frozen_fields|
          table_command = " UPDATE #{table_name} SET"
          frozen_fields.each do |field_name, assignments|
            assignments.each do |value, ids|
              update_command << "#{table_command} #{field_name} = '#{value}' WHERE id IN (#{ids.join(',')});"
            end
          end
        end
        "#{update_command.chop};"
      end

      # Save and track generated time of bootstrap with other metadata
      def save_metadata!
        settings = bootstrap_settings
        settings[:metadata] ||= {}

        STDOUT.puts "Saving metadata generated_on as : #{current_time.to_s}"
        #Set current bootstrap generated time
        settings[:metadata][:generated_on] = current_time.to_s(:db)
        #Set current offset at point of generation
        settings[:metadata][:generated_utc_offset] = Time.zone.utc_offset

        save_bootstrap_settings!(settings)
      end

      # TODO: Only run one write to file in settings generation
      # Save and track post processing commands
      def save_post_processing!
        log "Post process settings: #{current_settings}"
        settings = bootstrap_settings
        settings[:post_processing] ||= {}

        #Set current bootstrap generated time
        if ::Bootstrap::Db::Rebase.post_processing
          settings[:post_processing] = ::Bootstrap::Db::Rebase.post_processing
        end

        save_bootstrap_settings!(settings)
      end

      # Save and track generated time of bootstrap
      def save_frozen!
        settings = bootstrap_settings
        settings[:frozen] = {}

        if ::Bootstrap::Db::Rebase.frozen
          settings[:frozen] = ::Bootstrap::Db::Rebase.frozen
        end

        save_bootstrap_settings!(settings)
      end

      def save_settings!(settings)
        File.open(settings_path, "w") do |file|
          file.write settings.to_yaml
        end
      end

      def save_bootstrap_settings!(new_settings)
        save_settings!(current_settings.merge("#{file_path}" => new_settings))
      end

      def remove_old_bootstrap_settings!
        stripped_settings = current_settings

        #Clear any bootstraps that may have been removed
        stripped_settings.each do |file_path, bootstrap_data|
          stripped_settings.delete(file_path) unless File.exists?(file_path)
        end

        save_settings!(stripped_settings) unless stripped_settings == current_settings
      end

      def current_settings
        return {} unless File.exists?(settings_path)
        YAML::load_file(settings_path) || {}
      end

      def bootstrap_settings
        current_settings[file_path] || {}
      end

      def settings_path
        @settings_path ||= File.expand_path(File.join(config.bootstrap_dir, '.bootstrap'))
      end
    end
  end
end
