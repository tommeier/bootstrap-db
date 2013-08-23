# Bootstrap-DB

## Purpose

To be able to load and dump a database as quickly as possible.
Primary use is to load a large dataset quickly, with practical applications for running
test suites (with extensive seed data).

Some projects require extensive seed data, with many complex values, which can take excessive time to generate. The idea of this project is to create a 'snapshot' in time of this generated seed data, and be able to load almost instantly. With the time rebase task, this can also have the time and dates rebased to the current time, allowing relative time tests to work.

For example:
 * Running a project with multiple customer types and scenarios, with complex underlying data. This takes around ~55 seconds to generate. You don't want to run this for *every single test* you run. So on change of the data, recreate the dump, and set the test suite to load. Now it will take ~1 second.

## Add this line to your application's Gemfile:

```
  gem 'bootstrap-db'
```

## Commands (with example usage)

### Database Dump

```
  rake bootstrap:db:dump                                          #Dump default to db/bootstrap/bootstrap_data.sql
  rake bootstrap:db:dump RAILS_ENV=production                     #Dump specific Rails environment using database.yml
  rake bootstrap:db:dump BOOTSTRAP_DIR=db/my_bootstraps/          #Dump to specific directory
  rake bootstrap:db:dump FILE_NAME=live_database.dump             #Dump specific file to default bootstrap location
```

#### Additional options:

  * Dump file with comma delimited tables ignored:
```
  rake bootstrap:db:dump IGNORE_TABLES='messages,incidents'
```

### Database Rebuild and Dump

Recreate the database from scratch, seed and then dump.

```
  rake bootstrap:db:recreate                                      #Dump default to db/bootstrap/bootstrap_data.sql
```

### Database Load

Load, and overwrite, current database environment with a passed file name.

```
  rake bootstrap:db:load                                          #Load default from db/bootstrap/bootstrap_data.sql
  rake bootstrap:db:load RAILS_ENV=production                     #Load specific Rails environment using database.yml
  rake bootstrap:db:load BOOTSTRAP_DIR=db/custom_dir/             #Load from specific dump directory
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

### Database Time Rebaser

Load, and overwrite, current database environment with a passed snapshot. Then 'rebase' all date and time values from the generated snapshot point in time to 'now'.

Working example:
 * A customer may have an activity feed with a variety of tests to check date ranges of results. With the `time rebaser` task, this will actively loop over every date or time value in a db and `rebase` the time to a new point (comparing it to the generated time).
 * For this to work, you can only use *relative* time tests (1.week.ago, 4.months.ago, 5.years.from.now), as the rebaser doesn't know what should be fixed and not. You cannot generate data (and snapshot the dump) with data like `Time.zone.today.beginning_of_year` and expect the test to find the data. *All* date and time fields will be shifted based on the difference between when the data was generated and the load time.


*all the same options as `bootstrap:db:load` apply here too*
```
  rake bootstrap:db:load_and_rebase           #Load default from db/bootstrap/bootstrap_data.sql and rebase all time and date values
```

## Requirements

 * Rails
 * config/database.yml exists and set correctly
 * database.yml has a 'host' value set for environments
 * mysql/postgresql


## TODO
  * Write extensive readme examples
  * This has been quickly rebuilt from a ridiculously old project of mine (http://github.com/tommeier/bootstrap). This should be refactored into proper objects and expose classes as well as rake tasks. Fully tested.
  * List required attributes for each database (like `host` and raise on missing)
  * Clearly list options available to Rake tasks
  * Convert rake tasks to script tasks (if 'load_config' can be loaded)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Create some tests
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
