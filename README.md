# Bootstrap-DB

## Purpose

Collection of rake tasks for speeding up the capture and load of database snapshots (dumps).
Currently accepting MySQL & Postgres databases and specifically gear to Rails applications.

## Add this line to your application's Gemfile:

```
  gem 'bootstrap-db'
```

## Commands (with example usage)

### Database Dump

```
  rake bootstrap:db:dump                                          #Dump default to db/bootstrap/bootstrap_data.sql
  rake bootstrap:db:dump RAILS_ENV=production                     #Dump specific Rails environment using database.yml
  rake bootstrap:db:dump FILE=db/bootstrap/live_database_dump.sql #Dump to specific location
  rake bootstrap:db:dump FILE_NAME=live_database_dump.sql         #Dump specific file to default bootstrap location
```

#### Additional options:

  * Dump file with comma delimited tables ignored:
```
  rake bootstrap:db:dump IGNORE_TABLES='messages,incidents'
```

### Database Load

Load, and overwrite, current database environment with a passed file name.

```
  rake bootstrap:db:load                                          #Load default from db/bootstrap/bootstrap_data.sql
  rake bootstrap:db:load RAILS_ENV=production                     #Load specific Rails environment using database.yml
  rake bootstrap:db:load FILE=db/bootstrap/live_database_dump.sql #Load from specific dump
  rake bootstrap:db:load FILE_NAME=live_database_dump.sql         #Load specific file from default bootstrap location
```

### Additional options:

Pass in any additional parameters that your database accepts:
  * eg. mysqldump *--help* / pg_dump *--help*

```
  rake bootstrap:db:dump ADDITIONAL_PARAMS='-d,-t'
  rake bootstrap:db:load ADDITIONAL_PARAMS='-d,-t'
```

Pass 'VERBOSE=true' if you'd like to see more information. For example:

```
  rake bootstrap:db:dump VERBOSE=true
```

## Requirements

 * Rails
 * config/database.yml exists and set correctly
 * database.yml has a 'host' value set for environments
 * mysql/postgresql

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Create some tests
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
