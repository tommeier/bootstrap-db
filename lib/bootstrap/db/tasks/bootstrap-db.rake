require File.join(File.dirname(__FILE__), '../rake_helper')

namespace :bootstrap do
  namespace :db do
    include Bootstrap::Db::RakeHelper

    desc "Dump the current database to a SQL file"
    task :dump => :environment do
      config = Bootstrap::Db.load_config!

      sql_root        = File.join(Rails.root, 'db', 'bootstrap')
      ignore_tables   = ENV['IGNORE_TABLES'].split(',')     if ENV['IGNORE_TABLES']
      passed_params   = ENV['ADDITIONAL_PARAMS'].split(',') if ENV['ADDITIONAL_PARAMS']

      sql_filename, sql_path = if ENV['FILE']
        [ File.basename(ENV['FILE']), ENV['FILE'] ]
      else
        passed_filename = ENV['FILE_NAME'] || 'bootstrap_data.sql'

        [ passed_filename, File.join(sql_root, passed_filename) ]
      end

      #Create directories if they don't exist
      Dir.mkdir sql_root unless File.exists?(sql_root)

      log "Generating SQL Dump of Database - #{sql_path}"

      case config[Rails.env]["adapter"]
      when 'mysql'
        #mysqldump --help
        default_sql_attrs = "-q --add-drop-table --add-locks --extended-insert --lock-tables --single-transaction"
        if ignore_tables
          ignore_tables.each do |table_name|
            default_sql_attrs += " --ignore-table=#{config[Rails.env]["database"]}.#{table_name.strip}"
          end
        end

        if passed_params
          passed_params.each do |param|
            default_sql_attrs += " #{param}"
          end
        end

        password_attrs = " -p#{config[Rails.env]["password"]}" if config[Rails.env]["password"]
        #--all-tablespaces
        display_and_execute("mysqldump #{default_sql_attrs} -h #{config[Rails.env]["host"]} -u #{config[Rails.env]["username"]}#{password_attrs.to_s} #{config[Rails.env]["database"]} > #{sql_path}")

      when 'postgresql'
        #pg_dumpall --help
        default_sql_attrs = "-i --clean --inserts --column-inserts --no-owner --no-privileges"

        if ignore_tables.present?
          ignore_tables.each do |table_name|
            default_sql_attrs += " --exclude-table=#{config[Rails.env]["database"]}.#{table_name.strip}"
          end
        end

        if passed_params.present?
          passed_params.each do |param|
            default_sql_attrs += " #{param}"
          end
        end

        display_and_execute("pg_dumpall #{default_sql_attrs} --host=#{config[Rails.env]["host"]} --port=#{config[Rails.env]["port"] || 5432} --username=#{config[Rails.env]["username"]} --file=#{sql_path} --database=#{config[Rails.env]["database"]}")
      else
        raise "Error : Task not supported by '#{config[Rails.env]['adapter']}'"
      end
      log "SQL Dump completed --> #{sql_path}"
    end

    desc "Load a SQL dump into the current environment"
    task :database_load => :environment do
      config = Bootstrap::Db.load_config!

      log "No dump location passed. Loading defaults..." unless ENV['FILE']

      sql_path = ENV['FILE'] || File.join(Rails.root, 'db', 'bootstrap','bootstrap_data.sql')
      raise "Unable to find dump at location - #{sql_path}" unless File.exists?(sql_path)

      log "Loading dump: #{File.basename(sql_path)}"

      case config[Rails.env]["adapter"]
      when 'mysql'
        password_attrs = " -p#{config[Rails.env]["password"]}" if config[Rails.env]["password"]
        display_and_execute("mysql -f -h #{config[Rails.env]["host"]} -u #{config[Rails.env]["username"]}#{password_attrs.to_s} #{config[Rails.env]["database"]} < #{sql_filename}")
      when 'postgresql'
        default_sql_attrs = "--single-transaction"
        display_and_execute("psql #{default_sql_attrs} --host=#{config[Rails.env]["host"]} --port=#{config[Rails.env]["port"] || 5432} --dbname=#{config[Rails.env]["database"]} --username=#{config[Rails.env]["username"]} < #{sql_path}")
      else
        raise "Task not supported by '#{config[Rails.env]['adapter']}'"
      end
      puts "Database load completed..."
    end
  end
end
