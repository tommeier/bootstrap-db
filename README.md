# Bootstrap-DB

## Purpose

Collection of rake tasks for speeding up the capture and load of database snapshots (dumps).
Currently accepting MySQL & Postgres databases and specifically gear to Rails applications.

## Add this line to your application's Gemfile:

```
    gem 'bootstrap-db'
```

## Commands (with example usage)

### Bootstrap - Database Dump / Load
    rake bootstrap:db:dump
    rake bootstrap:db:dump RAILS_ENV=production              #Dump specific environment using database.yml
    rake bootstrap:db:dump file=db/bootstrap/live_database_dump.sql    #Dump to specified location
    rake bootstrap:db:dump file_name=live_database_dump.sql        #Dump file to default bootstrap location
    rake bootstrap:db:dump bootstrap=true                #Dump default bootstrap file (for use in specs and initial clean DB load - db/bootstrap/bootstrap_data.sql)
    rake db:database_dump ignore_tables='messages,incidents'      #Dump file with certain tables ignored (useful when generating multiple dumps and concatenating)
    rake db:database_dump additional_params='-d,-t'           #Pass in any additional parameters that your database accepts (eg. mysqldump --help / pg_dump --help)

rake db:database_dump RAIlS_ENV=live_export ignore_tables='messages,incidents,entities' additional_params='-d,-t'
Create a database dump of the environment in a specified or default location for loading later (or just as a backup file). This will overwrite any file by the same name, so if used for backup specify a unique filename.

    rake db:database_load                       #Load default bootstrap file ( db/bootstrap/bootstrap\_data.sql)
    rake db:database_load file=db/bootstrap/live_database_dump.sql    #Load the sql dump file specified

Load, and overwrite, current database environment with a passed file name.

Pass 'display=true' if you'd like to see the command being output to your database. For example:
    rake db:database_dump display=true

### Bootstrap - RSPEC Integration

To enable specs to be loaded from an SQL dump, with migrations, edit your rspec.rake file and alter the spec\_prereq variable to run the following rake command: db:test:custom\_prepare (instead of db:test:prepare). With this you can run with a default data set, or your complete data set for thorough testing purposes simply by running : rake spec.
You can also load a different 'custom' spec database by running with the file parameter.
eg. rake spec file=db/bootstrap/my_spec_fixtures.sql

### Bootstrap - Database Backup
    rake db:database_backup                             #Backup the database to default location ('/db/backups'), to a maximum of 5 files
    rake db:database_backup total_backups=2             #Maintain only a maximum of 2 backup files (keep most recent)
    rake db:database_backup backup_location=db/custom_location/save_here  #Set the backup location to a custom location

This task will save a database dump to a folder, and maintain a set number. Default is 5. This is best paired with a cron task to run at regular intervals.

### Bootstrap - Data Extractors (BETA)
    rake db:extract_data_migrations
    rake db:extract_data_migrations table=users

Extract existing data from all database tables or a specified table into a generated migration file. Can be useful for having effective rollback statements when deleting records. Generated migrations are saved into : "#{RAILS\_ROOT}/tmp/generated\_migrations".

    rake db:extract_fixtures

Current contents of the database is extracted into numbered yml files, able to be processed by "rake db:bootstrap:load" command. YML files are saved : "#{RAILS\_ROOT}/tmp/generated\_ymls" and will need to be moved to default bootstrap directory when satisifed with ordering.

## Requirements

 * ActiveRecord / DataMapper
 * config/database.yml exists and set correctly
 * database.yml has a 'host' value set for environments
 * mysql/postgresql - for database dump/load

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Create some tests
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
