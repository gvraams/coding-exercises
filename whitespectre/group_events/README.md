# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version: 2.7.1

* Configuration

* Database creation:
```
RAILS_ENV=dev rake db:drop:_unsafe
RAILS_ENV=dev rake db:create
```

* Database initialization
```
RAILS_ENV=dev rake db:migrate
```

* How to run the test suite
```
rake db:drop:_unsafe
rake db:create
rake db:migrate
rspec --format documentation spec/
```

* Services (job queues, cache servers, search engines, etc.)
NA

* Deployment instructions
NA
