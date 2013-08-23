require File.join(File.dirname(__FILE__), '../rake_helper')

namespace :bootstrap do
  namespace :db do
    include Bootstrap::Db::RakeHelper

    desc "Recreate bootstrap (drop, create + seed)"
    task :recreate => ['db:drop', 'db:setup', :dump]

    desc "Dump the current database to a SQL file"
    task :dump => 'db:load_config' do
      config = Bootstrap::Db::Config.load!

      settings        = config.settings[Rails.env]
      ignore_tables   = ENV['IGNORE_TABLES'].split(',')     if ENV['IGNORE_TABLES']
      passed_params   = ENV['ADDITIONAL_PARAMS'].split(',') if ENV['ADDITIONAL_PARAMS']

      #Create directories if they don't exist
      Dir.mkdir config.dump_dir unless File.exists?(config.dump_dir)

      log "Generating dump of database: '#{config.dump_name}'"

      case config.adapter
      when :mysql
        #mysqldump --help
        default_sql_attrs = "-q --add-drop-table --add-locks --extended-insert --lock-tables --single-transaction"
        if ignore_tables
          ignore_tables.each do |table_name|
            default_sql_attrs += " --ignore-table=#{settings["database"]}.#{table_name.strip}"
          end
        end

        if passed_params
          passed_params.each do |param|
            default_sql_attrs += " #{param}"
          end
        end

        password_attrs = " -p#{settings["password"]}" if settings["password"]
        #--all-tablespaces
        display_and_execute("mysqldump #{default_sql_attrs} -h #{settings["host"]} -u #{settings["username"]}#{password_attrs} #{settings["database"]} > #{config.dump_path}")

      when :postgresql
        #pg_dump --help
        #trial without --clean
        default_sql_attrs = "--create --format=c"

        if ignore_tables.present?
          ignore_tables.each do |table_name|
            default_sql_attrs += " --exclude-table=#{settings["database"]}.#{table_name.strip}"
          end
        end

        if passed_params.present?
          passed_params.each do |param|
            default_sql_attrs += " #{param}"
          end
        end

        user_attribute = " --username=#{settings["username"]}" if settings['username']

        display_and_execute("pg_dump #{default_sql_attrs} --host=#{settings["host"]} --port=#{settings["port"] || 5432}#{user_attribute} --file=#{config.dump_path} #{settings["database"]}")
      else
        raise "Error : Task not supported by '#{settings['adapter']}'"
      end
      log "Dump completed --> '#{config.dump_path}'"
    end

    desc "Load a SQL dump into the current environment"
    task :load => ['db:load_config'] do
      config    = Bootstrap::Db::Config.load!
      settings  = config.settings[Rails.env]
      raise "Unable to find dump at location - '#{config.dump_path}'" unless File.exists?(config.dump_path)

      log "Loading dump: '#{config.dump_name}'"

      case config.adapter
      when :mysql
        password_attrs = " -p#{settings["password"]}" if settings["password"]
        display_and_execute("mysql -f -h #{settings["host"]} -u #{settings["username"]}#{password_attrs.to_s} #{settings["database"]} < #{config.dump_path}")
      when :postgresql
        #--clean --create --single-transaction
        # cannot use --create and --single-transaction together
        #--clean
        default_sql_attrs = "--single-transaction --format=c"
        user_attribute    = " --username=#{settings["username"]}" if settings['username']
        display_and_execute("pg_restore #{default_sql_attrs} --host=#{settings["host"]} --port=#{settings["port"] || 5432} --dbname=#{settings["database"]}#{user_attribute} #{config.dump_path}")
      else
        raise "Task not supported by '#{settings['adapter']}'"
      end

      log "Database load completed..."
    end

    desc "Load a SQL dump and rebase the time to this point in time"
    task :load_and_rebase => ['db:load_config', :load] do
      config    = Bootstrap::Db::Config.load!
      settings  = config.settings[Rails.env].symbolize_keys
      raise "Unable to find dump at location - '#{config.dump_path}'" unless File.exists?(config.dump_path)

      command_path = File.expand_path('../../sql/rebase_time.sql', __FILE__)
      #all_fields = File.expand_path('../../sql/select_date_time_fields.sql', __FILE__)
      generated_time = File.mtime(config.dump_path)

      log "Rebasing database time to: '#{generated_time}'"

      # Table name, and field name
      # SELECT MIN(field_name) FROM table_name
      # (to calculate at which is the overall generated/seeded point of db)
      case config.adapter
      when :mysql
        raise "Not supported yet. Sorry"
      when :postgresql
        # Using pg adapter
        #%w[host port options tty dbname user password]
         # require 'pg'

         # connection = {port: settings[:port] || 5432}
         # connection.merge!(user: settings[:username])    #if settings[:username]
         # connection.merge!(password: settings[:password]) #if settings[:password]
         # connection.merge!(host: settings[:host])        #if settings[:host]
         # connection.merge!(dbname: settings[:database])  #if settings[:database]
         # puts connection.inspect
         # # Output a table of current connections to the DB
         # connection_string = PG::Connection.parse_connect_args(connection)
         # puts "Connection string: "
         # puts connection_string.inspect
#exit 1
         #conn = PG.connect( connection )

        # all_time_fields_sql = <<-SQL
        # SELECT table_name, column_name, data_type
        # FROM information_schema.columns
        # WHERE
        # table_schema = 'public'
        # AND data_type IN
        # ('timestamp without time zone',
        # 'timestamp with time zone',
        # 'date')
        # ORDER BY table_name, data_type, column_name DESC
        # SQL

        # table_set = {}
        # # Group tables by type and fields
        # conn.exec( all_time_fields_sql ) do |result|
        #   #result.symbolize_keys!
        #   #tables = result.group_by(&:table_name)
        #   #puts tables.inspect
        #   result.each do |row|
        #     table_name = row['table_name'].to_sym
        #     table_set[table_name] ||= {}
        #     type = row['data_type'] == 'date' ? :date : :time

        #     table_set[table_name.to_sym][type] ||= []
        #     table_set[table_name.to_sym][type] << row['column_name']
        #   end
        # end

        #puts table_set.inspect
        # End of ruby way

        # TODO: Load/create the functions
        #

        user_attribute    = " --username=#{settings[:username]}" if settings[:username]
        host_attribute    = " --host=#{settings[:host]}"         if settings[:host]
        db_attribute      = " --dbname=#{settings[:database]}"   if settings[:database]

        psql_command = "psql --port=#{settings[:port] || 5432} #{db_attribute}#{host_attribute}#{user_attribute}"
        #psql_command = "psql #{connection_string}"
        # Load functions
        display_and_execute("#{psql_command} --file='#{command_path}'")
        # Get start point
        cmd = "SELECT MIN(created_at) FROM CUSTOMERS"
        result = display_and_execute("#{psql_command} --command='#{cmd}'")
        puts result.inspect
        #TODO: Make this better!
        start_point = result.scan(/(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}\.\d{6})/).flatten.first
        #2013-08-01 22:44:33.784762
        #exit 1

        if time_zone = (ENV['ZONEBIE_TZ'] || ENV['TZ'])
          STDERR.puts "CUSTOM ZONE: #{time_zone}"
          #Handle custom timezones
          Time.zone = time_zone
          new_point = Time.zone.now.to_formatted_s(:db)
          #start_point = "2013-08-01 22:44:33.000000"
          #start_point = Time.zone.parse(start_point).to_formatted_s(:db)
        else
          # Default to 'now' in the local timestamp
          new_point = "localtimestamp"
          #start_point = "2013-08-01 22:44:33.000000"
        end

        STDERR.puts "NEW_POINT : #{new_point}"
        STDERR.puts "start_point : #{start_point}"


        #Working (3rd aug)
        #start_point = "2013-08-03 22:30:27.000000"
        #test without create on dump
        #start_point = "2013-08-01 22:44:33.000000"
        #new_point = Time.zone.now.to_formatted_s(:db)
        #new_point = "localtimestamp"
        # Rebase time
        cmd = "SELECT rebase_db_time('#{start_point}'::timestamp without time zone, '#{new_point}'::timestamp without time zone);"
        puts cmd
        result = display_and_execute("#{psql_command} --command=#{cmd.shellescape}")
        puts "RESULT : "
        puts result.inspect

        #{}"SELECT rebase_db_time('2013-07-24 12:26:50.598673'::timestamp, '2013-08-13 07:14:39.000000'::timestamp);"

        #result = display_and_execute("psql --port=#{settings["port"] || 5432} #{db_attribute}#{host_attribute}#{user_attribute} --file='#{all_fields}'")
   #      puts result.inspect
   #      #table_name, column_name, data_type
   #      puts "---"
   #      result.each do |row|
   #        puts " %s | %s | %s" % row.values_at( 'table_name', 'column_name', 'data_type')
   #        #puts " %7d | %-16s | %s " %
   # #26:         row.values_at('table_name', 'column_name', 'data_type')
   #      end
      else
        raise "Task not supported by '#{settings['adapter']}'"
      end

      log "Database rebase completed..."
    end
  end
end
