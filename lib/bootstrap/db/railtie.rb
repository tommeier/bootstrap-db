module Bootstrap
  module Db
    class Railtie < Rails::Railtie
      rake_tasks do
        load "bootstrap/db/tasks/bootstrap-db.rake"
      end
    end
  end
end
