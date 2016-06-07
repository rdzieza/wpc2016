# WPC Project

### Requirements

We assume you've **Bundler** installed on your machine. So everytime you add any dependency to **Gemfile** make sue you've run `bundle update`, so it resolves dependencies correctly and **Rack** won't yell at you!

### How to run

Got to directory and run:
```
bundle install
```

To run server fire this command:
```
rackup
```

Running on Amazon EC2?
```
rackup -p 5000 -o 0.0.0.0
```

Running queue listener:
```
ruby queue.rb &
```
