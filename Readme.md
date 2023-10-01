# Postgresql transaction isolation level test with RSpec and Ruby

## To prepare do:

```bash
bundle install
```

## To start pg:

```bash
docker-compose up -d
```

## To run examples:

```bash
bundle exec rspec
```

Also, you can run each example separately:

```bash
bundle exec rspec spec/read_committed_spec.rb
```
