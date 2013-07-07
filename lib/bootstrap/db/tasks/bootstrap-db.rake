require File.join(File.dirname(__FILE__), '../rake_helper')

namespace :bootstrap do
  namespace :db do
    include Bootstrap::Db::RakeHelper

    desc "Dump the current database to a SQL file"
    task :dump => :environment do
      config = Bootstrap::Db::Config.load!
      raise "Unable to find dump at location - #{config.dump_path}" unless File.exists?(config.dump_path)

      settings        = config.settings[Rails.env]
      ignore_tables   = ENV['IGNORE_TABLES'].split(',')     if ENV['IGNORE_TABLES']
      passed_params   = ENV['ADDITIONAL_PARAMS'].split(',') if ENV['ADDITIONAL_PARAMS']

      #Create directories if they don't exist
      Dir.mkdir config.dump_dir unless File.exists?(config.dump_dir)

      log "Generating dump of database to #{config.dump_name}"

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
        display_and_execute("mysqldump #{default_sql_attrs} -h #{settings["host"]} -u #{settings["username"]}#{password_attrs} #{settings["database"]} > #{path}")

      when :postgresql
        #pg_dump --help
        default_sql_attrs = "--clean --format=c"

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

        display_and_execute("pg_dump #{default_sql_attrs} --host=#{settings["host"]} --port=#{settings["port"] || 5432}#{user_attribute} --file=#{path} #{settings["database"]}")
      else
        raise "Error : Task not supported by '#{settings['adapter']}'"
      end
      log "Dump completed --> #{config.dump_path}"
    end

    desc "Load a SQL dump into the current environment"
    task :load => :environment do
      config    = Bootstrap::Db::Config.load!
      settings  = config.settings[Rails.env]
      raise "Unable to find dump at location - '#{config.dump_path}'" unless File.exists?(config.dump_path)

      log "Loading dump: #{config.dump_name}"

      case config.adapter
      when :mysql
        password_attrs = " -p#{settings["password"]}" if settings["password"]
        display_and_execute("mysql -f -h #{settings["host"]} -u #{settings["username"]}#{password_attrs.to_s} #{settings["database"]} < #{config.dump_path}")
      when :postgresql
        default_sql_attrs = "--exit-on-error --clean --single-transaction --format=c"
        user_attribute    = " --username=#{settings["username"]}" if config[Rails.env]['username']
        display_and_execute("pg_restore #{default_sql_attrs} --host=#{settings["host"]} --port=#{settings["port"] || 5432} --dbname=#{settings["database"]}#{user_attribute} #{config.dump_path}")
      else
        raise "Task not supported by '#{settings['adapter']}'"
      end

      log "Database load completed..."
    end
  end
end
