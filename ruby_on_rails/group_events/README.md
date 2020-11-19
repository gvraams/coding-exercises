# README

Please ensure that you have Ruby (version: 2.7.1), SQLite3 installed in your system.
Check out this repository and run `bundle` command to install the Gems.

* Database creation:
SQLite3 database is used for speedy tests

* Database initialization
```
RAILS_ENV=test bundle exec rake db:drop:_unsafe
RAILS_ENV=test bundle exec rake db:create
RAILS_ENV=test bundle exec rake db:migrate
```

* How to run the test suite
```
rspec spec/
```

* To create User & Location objects, log into rails console with `bundle exec rails c` and execute:
```
user     = User.create uuid: SecureRandom.uuid, name: "Name", email: "someemail@domain.com", password: "password"
location = Location.create uuid: SecureRandom.uuid, name: "Place"
```
