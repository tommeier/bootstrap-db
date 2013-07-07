require File.join(File.dirname(__FILE__), '../rake_helper')

namespace :bootstrap do
  namespace :db do
    include Bootstrap::Db::RakeHelper

    desc "Dump the current database to a SQL file"
    task :dump do
      config = load_config
      raise_common_errors(config)

      passed_file     = ENV['file']
      passed_filename = ENV['bootstrap'] == true ? 'bootstrap_data.sql' : ENV['file_name']
      sql_root        = File.join(RAILS_ROOT, 'db', 'bootstrap')
      ignore_tables   = ENV['ignore_tables'].split(',') if ENV['ignore_tables'].present?
      passed_params   = ENV['additional_params'].split(',') if ENV['additional_params'].present?
      display         = ENV['display']

      if passed_file.blank?
        sql_filename  = passed_filename || "#{RAILS_ENV}_database_dump.sql"
        sql_path      = File.join(sql_root,sql_filename)
      else
        sql_filename  = File.basename(ENV['file'])
        sql_path      = ENV['file']
      end

      #Create directories if they don't exist
      Dir.mkdir sql_root if !File.exists?(sql_root)

      puts "Generating SQL Dump of Database - #{sql_path}"

      case config[RAILS_ENV]["adapter"]
      when 'mysql'
        #mysqldump --help
        default_sql_attrs = "-q --add-drop-table --add-locks --extended-insert --lock-tables --single-transaction"
        if ignore_tables.present?
          ignore_tables.each do |table_name|
            default_sql_attrs += " --ignore-table=#{config[RAILS_ENV]["database"]}.#{table_name.strip}"
          end
        end

        if passed_params.present?
          passed_params.each do |param|
            default_sql_attrs += " #{param}"
          end
        end

        password_attrs = " -p#{config[RAILS_ENV]["password"]}" if config[RAILS_ENV]["password"].present?
        #--all-tablespaces
        display_and_execute("mysqldump #{default_sql_attrs} -h #{config[RAILS_ENV]["host"]} -u #{config[RAILS_ENV]["username"]}#{password_attrs.to_s} #{config[RAILS_ENV]["database"]} > #{sql_path}", display)
      when 'postgres', 'postgresql'
        #pg_dumpall --help
        default_sql_attrs = "-i --clean --inserts --column-inserts --no-owner --no-privileges"

        if ignore_tables.present?
          ignore_tables.each do |table_name|
            default_sql_attrs += " --exclude-table=#{config[RAILS_ENV]["database"]}.#{table_name.strip}"
          end
        end

        if passed_params.present?
          passed_params.each do |param|
            default_sql_attrs += " #{param}"
          end
        end

        display_and_execute("pg_dumpall #{default_sql_attrs} --host=#{config[RAILS_ENV]["host"]} --port=#{config[RAILS_ENV]["port"] || 5432} --username=#{config[RAILS_ENV]["username"]} --file=#{sql_path} --database=#{config[RAILS_ENV]["database"]}", display)
      else
        raise "Error : Task not supported by '#{config[RAILS_ENV]['adapter']}'"
      end
      puts "SQL Dump completed --> #{sql_path}"
    end

    desc "Loads the SQL dump into the current environment"
    task :database_load do
      load 'config/environment.rb' unless Object.const_defined?(:ActiveRecord)

      config = load_config
      raise_common_errors(config)

      display         = ENV['display']
      sql_filename    = ENV['file'] || File.join('db', 'bootstrap','bootstrap_data.sql')

      puts "No file location passed. Loading bootstrap defaults..." if ENV['file'].blank?
      puts "Attempting to load data... #{sql_filename}"

      sql_path = File.join(RAILS_ROOT, sql_filename)

      raise "Unable to find SQL file to load at location - #{sql_path}" if !File.exists?(sql_path)

      puts "Importing Database SQL..."

      case config[RAILS_ENV]["adapter"]
      when 'mysql'
        password_attrs = " -p#{config[RAILS_ENV]["password"]}" if config[RAILS_ENV]["password"].present?
        display_and_execute("mysql -f -h #{config[RAILS_ENV]["host"]} -u #{config[RAILS_ENV]["username"]}#{password_attrs.to_s} #{config[RAILS_ENV]["database"]} < #{sql_filename}", display)
      when 'postgres', 'postgresql'
        default_sql_attrs = "--single-transaction"
        display_and_execute("psql #{default_sql_attrs} --host=#{config[RAILS_ENV]["host"]} --port=#{config[RAILS_ENV]["port"] || 5432} --dbname=#{config[RAILS_ENV]["database"]} --username=#{config[RAILS_ENV]["username"]} < #{sql_path}", display)
      else
        raise "Task not supported by '#{config[RAILS_ENV]['adapter']}'"
      end
      puts "Database load completed..."
    end

    desc "Backup the mysql db to a set number of dump files"
    task :database_backup do
      load 'config/environment.rb' unless Object.const_defined?(:ActiveRecord)
      config = load_config
      raise_common_errors(config)

      backup_numbers  = ENV['total_backups'].present? ? ENV['total_backups'].to_i : 5
      backup_location = ENV['backup_location'] || File.join(RAILS_ROOT, 'db', 'backup')

      #Create directories if they don't exist
      Dir.mkdir backup_location if !File.exists?(backup_location)

      puts "No 'total_backups' passed. Setting maximum backup files : #{backup_numbers}..." if ENV['total_backups'].blank?
      puts "No 'backup_location' passed. Saving to : #{backup_location}..." if ENV['backup_location'].blank?

      #Check for current releases
      Dir.chdir(backup_location) do
        #Delete records
        sorted_files = Dir.glob("*.sql").sort_by {|f| test(?M, f)}
        puts " -- Found #{sorted_files.size} backup files"
        if sorted_files.size >= backup_numbers
          puts "Cleaning up backups..."
          sorted_files.reverse.each_with_index do |file, i|
            if i >= (backup_numbers - 1)
              FileUtils.rm( file )
            end
          end
        end
      end

      sql_filename = "#{Time.now.strftime("%Y%m%d").to_s}_#{Time.now.strftime("%H%M%S")}.sql"
      puts "Attempting to dump data... #{sql_filename}"

      ENV['file'] = File.join(backup_location, sql_filename)
      run_rake('db:database_dump')

      puts "Backup complete."
    end

  end
end
