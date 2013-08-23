namespace :bootstrap do
  namespace :db do
    include Bootstrap::Db::Log

    desc "Recreate bootstrap (drop, create + seed)"
    task :recreate => ['db:drop', 'db:setup', :dump]

    desc "Dump the current database to a SQL file"
    task :dump => ['db:load_config'] do
      config = Bootstrap::Db::Config.load!

      bootstrap = case config.adapter
      when :mysql
        Bootstrap::Db::Mysql.new(config)
      when :postgresql
        Bootstrap::Db::Postgres.new(config)
      else
        raise "Error : Task not supported by '#{config.adapter}'"
      end

      log("Here it is #{Time.zone.now.to_s(:db)}")
      log "Generating dump of database: '#{bootstrap.file_name}'"
      bootstrap.dump!
      log "Dump completed --> '#{bootstrap.file_path}'"
    end

    desc "Load a SQL dump into the current environment"
    task :load => ['db:load_config'] do
      config    = Bootstrap::Db::Config.load!

      bootstrap = case config.adapter
      when :mysql
        Bootstrap::Db::Mysql.new(config)
      when :postgresql
        Bootstrap::Db::Postgres.new(config)
      else
        raise "Task not supported by '#{config.adapter}'"
      end

      unless File.exists?(bootstrap.file_path)
        raise "Unable to find dump at location - '#{bootstrap.file_path}'"
      end

      log "Loading dump: '#{bootstrap.file_name}'"
      bootstrap.load!

      log "Database load completed..."
    end

    desc "Load a SQL dump and rebase the time to this point in time"
    task :load_and_rebase => ['db:load_config', :load] do
      config    = Bootstrap::Db::Config.load!
      settings  = config.settings.symbolize_keys

      bootstrap = case config.adapter
      when :mysql
        raise "Not supported yet. Sorry"
      when :postgresql
        Bootstrap::Db::Postgres.new(config)
      else
        raise "Task not supported by '#{settings['adapter']}'"
      end

      unless File.exists?(bootstrap.file_path)
        raise "Unable to find dump at location - '#{bootstrap.file_path}'"
      end

      log "Rebasing database time to now..."

      bootstrap.rebase!

      log "Database rebase completed..."
    end
  end
end
