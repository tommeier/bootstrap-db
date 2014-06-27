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
          # Time.zone = 'UTC'
          #generated_time = ActiveSupport::TimeZone['UTC'].parse(generated_time)
          #generated_time = ActiveSupport::TimeZone["Nuku'alofa"].parse(generated_time)
          generated_time = ActiveSupport::TimeZone["American Samoa"].parse(generated_time)

          if current_time >= generated_time
            STDOUT.puts "++>>> current_time > generated_time"
            #generated_time -= (generated_time - current_time).seconds
          else
            STDOUT.puts "++<<< current_time < generated_time"
            #SHOULD ADD TO TIME:
            #[bootstrap-db] Rebasing database time relative to now...
            # Setting with zone : 2014-06-27 04:35:57 -0300
            # > local_offset           : -10800
            # > generated_utc_offset   : -39600
            # Setting with zone : 2014-06-27 04:35:57 -0300
            # > current_time           : 2014-06-27 04:35:57 -0300
            # > generated_time         : 2014-06-27 07:33:06
            # Setting with zone : 2014-06-27 04:35:57 -0300
            # ++<<< current_time < generated_time
            # Setting with zone : 2014-06-27 04:35:57 -0300
            # Parsed generated_time : 2014-06-26 20:35:57 -1100
            # >+> Generated output : 2014-06-27 07:35:57

            # American Samoa generated
            # ZONEBIE_TZ="Azores" FUB_UPDATE=false be rspec --tag wip spec/features/activity/filter_activity_feed.feature
            # ZONEBIE_TZ="Atlantic Time (Canada)" FUB_UPDATE=false be rspec --tag wip spec/features/activity/filter_activity_feed.feature
            # ZONEBIE_TZ="American Samoa" FUB_UPDATE=false be rspec --tag wip spec/features/activity/filter_activity_feed.feature
            # ZONEBIE_TZ="Yerevan" FUB_UPDATE=false be rspec --tag wip spec/features/activity/filter_activity_feed.feature
            #generated_time += (current_time - generated_time).seconds
            #generated_time -= (current_time - generated_time).abs.seconds

            # Failed
            # ZONEBIE_TZ="Nuku'alofa" FUB_UPDATE=false be rspec --tag wip spec/features/activity/filter_activity_feed.feature
            STDOUT.puts "Result : (current_time - generated_time) : #{(current_time - generated_time)}"
            if local_offset <= 0 && generated_utc_offset <= 0
              generated_time += (current_time - generated_time).seconds
            elsif local_offset >= 0 && generated_utc_offset >= 0
              generated_time -= offset_diff(local_offset, generated_utc_offset).seconds
            else
              generated_time
            end


            #generated_time -= (current_time - generated_time).seconds
          end




          # FAILED
          # Setting with zone : 2014-06-27 20:28:23 +1300
          # > local_offset           : 46800
          # > generated_utc_offset   : -39600
          # Setting with zone : 2014-06-27 20:28:23 +1300
          # > current_time           : 2014-06-27 20:28:23 +1300
          # > generated_time         : 2014-06-27 07:26:53
          # Setting with zone : 2014-06-27 20:28:23 +1300
          # ++<<< current_time < generated_time
          # Setting with zone : 2014-06-27 20:28:23 +1300
          # Parsed generated_time : 2014-06-26 20:28:23 -1100






          #generated_time = Time.zone.parse(generated_time)

          #generated_zone = metadata[:]

#           Setting with zone : 2014-06-27 06:35:44 +0000
# > local_offset           : 0
# > generated_utc_offset   : 46800
# Setting with zone : 2014-06-27 06:35:44 +0000
# > current_time           : 2014-06-27 06:35:44 +0000
# > generated_time         : 2014-06-27 06:29:55
# Setting with zone : 2014-06-27 06:35:44 +0000
# << local_offset < generated_utc_offset
# BOTH ABOVE OR BELOW GMT
          STDOUT.puts "Parsed generated_time : #{generated_time}"

          # if generated_time > current_time
          #   STDOUT.puts ">> generated_time > current_time"
          # #   # Reset to current time with difference removed
          #   generated_time = current_time - (generated_time - current_time).seconds
          # end

          # if local_offset > generated_utc_offset

          #   STDOUT.puts ">> local_offset > generated_utc_offset"
          #   generated_time += offset_diff(local_offset, generated_utc_offset).seconds
          # else
          #   STDOUT.puts "<< local_offset < generated_utc_offset"
          #   #generated_time
          #   generated_time -= offset_diff(local_offset, generated_utc_offset).seconds


          #   #generated_time -= (generated_utc_offset.abs + local_offset.abs).seconds #(31st Dec + 1st Jan) .parse
          # end



#           if generated_utc_offset > local_offset
#             STDOUT.puts "<< generated_utc_offset > local_offset"
#             # Remove the time zone differential
#             generated_time = generated_time - (generated_utc_offset.abs + local_offset.abs).seconds #(31st Dec + 1st Jan) .parse
#           else #generated_utc_offset < local_offset
#             # Add time zone differential
#             # generated_time = generated_time + (generated_utc_offset.abs + local_offset.abs).seconds #(1st Jan 2nd jan)
#             STDOUT.puts ">> WITHIN generated_utc_offset < local_offset"
#             if local_offset < 0 && generated_utc_offset < 0 then
#               STDOUT.puts "+-> BOTH ARE LESS THAN 0"

#               # Cannot do it here
#             elsif local_offset > 0 && generated_utc_offset > 0 then
#               STDOUT.puts "+-> BOTH ARE GREATER THAN 0"
#               generated_time = generated_time + (generated_utc_offset.abs + local_offset.abs).seconds #(1st Jan 2nd jan)
#             else
#               STDOUT.puts "+-> ONE IS DIFFERENT"

# #[bootstrap-db] Database rebase completed...

#               if local_offset > generated_utc_offset
#                 generated_time += offset_diff(local_offset, generated_utc_offset).seconds
#               else
#                 generated_time -= offset_diff(local_offset, generated_utc_offset).seconds
#               end
#             end
#           end
          generated_time = generated_time.to_s(:db)
          STDOUT.puts ">+> Generated output : #{generated_time}"
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
        settings[:metadata][:generated_time_zone] = Time.zone.name

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

#       Setting with zone : 2014-06-27 19:09:25 +1300
# > local_offset           : 46800
# > generated_utc_offset   : -39600
# > current_time           : 2014-06-27 19:09:25 +1300
# > generated_time         : 2014-06-27 06:07:50
# Setting with zone : 2014-06-27 19:09:25 +1300
# >> WITHIN generated_utc_offset < local_offset
# +-> ONE IS DIFFERENT

      def offset_diff(first_offset, second_offset)
        if (first_offset > 0 && second_offset > 0) ||
           (first_offset < 0 && second_offset < 0)
          #both above GMT or both behind GMT
          STDOUT.puts "BOTH ABOVE OR BELOW GMT"
          if first_offset > second_offset
            first_offset.abs - second_offset.abs
          else
            second_offset.abs - first_offset.abs
          end
        elsif first_offset <= 0 && second_offset >= 0
          #first is before GMT, second is after GMT
          STDOUT.puts "FIRST BEFORE GMT, SECOND AFTER GMT"
          first_offset.abs + second_offset

        elsif first_offset >= 0 && second_offset <= 0
          #first is after GMT, second is before GMT
          STDOUT.puts "FIRST AFTER GMT, SECOND BEFORE GMT"
          second_offset.abs + first_offset.abs
        else
          raise "FUCKING HELL. Unhandled situation."
        end



        # if first_number > second_number
        #   first_number.abs - second_number.abs
        # else
        #   second_number.abs - first_number.abs
        # end
      end
    end
  end
end
