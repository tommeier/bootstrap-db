namespace :bootstrap do
  namespace :db do
    include Bootstrap::Db::Log

    desc "Recreate bootstrap (drop, create + seed)"
    task :recreate => ['db:drop', 'db:setup', :dump]

    desc "Dump the current database to a SQL file"
    task :dump => 'db:load_config' do
      config = Bootstrap::Db::Config.load!

      #Create directories if they don't exist
      Dir.mkdir config.dump_dir unless File.exists?(config.dump_dir)

      log "Generating dump of database: '#{config.dump_name}'"

      bootstrap = case config.adapter
      when :mysql
        Bootstrap::Db::Mysql.new(config)
      when :postgresql
        Bootstrap::Db::Postgres.new(config)
      else
        raise "Error : Task not supported by '#{config.adapter}'"
      end

      bootstrap.dump!

      log "Dump completed --> '#{config.dump_path}'"
    end

    desc "Load a SQL dump into the current environment"
    task :load => ['db:load_config'] do
      config    = Bootstrap::Db::Config.load!

      unless File.exists?(config.dump_path)
        raise "Unable to find dump at location - '#{config.dump_path}'"
      end

      log "Loading dump: '#{config.dump_name}'"

      bootstrap = case config.adapter
      when :mysql
        Bootstrap::Db::Mysql.new(config)
      when :postgresql
        Bootstrap::Db::Postgres.new(config)
      else
        raise "Task not supported by '#{settings['adapter']}'"
      end
      bootstrap.load!

      log "Database load completed..."
    end

    desc "Load a SQL dump and rebase the time to this point in time"
    task :load_and_rebase => ['db:load_config', :load] do
      config    = Bootstrap::Db::Config.load!
      settings  = config.settings.symbolize_keys
      raise "Unable to find dump at location - '#{config.dump_path}'" unless File.exists?(config.dump_path)

      #command_path = File.expand_path('../../sql/rebase_time.sql', __FILE__)
      #all_fields = File.expand_path('../../sql/select_date_time_fields.sql', __FILE__)
      generated_time = File.mtime(config.dump_path)

      log "Rebasing database time to: '#{generated_time}' / #{File.ctime(config.dump_path)}"

      bootstrap = case config.adapter
      when :mysql
        raise "Not supported yet. Sorry"
      when :postgresql
        Bootstrap::Db::Postgres.new(config)
      else
        raise "Task not supported by '#{settings['adapter']}'"
      end

      bootstrap.rebase!

      log "Database rebase completed..."
    end
  end
end
