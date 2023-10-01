# Postgresql transaction isolation level test with RSpec and Ruby

## How to use this examples:
### To prepare:

```bash
bundle install
```

### To start pg:

```bash
docker-compose up -d
```

### To run examples:

```bash
bundle exec rspec
```

Also, you can run each example separately:

```bash
bundle exec rspec spec/read_committed/dirty_read_spec.rb
```

## List of examples

* [spec/accounts_spec.rb](spec/accounts_spec.rb) - This spec checks that the connection to the database is established and the accounts table contains data.
* [spec/read_committed/dirty_read_spec.rb](spec/read_committed/dirty_read_spec.rb) - This spec demonstrates dirty reads allowed at the read committed isolation level.
* [spec/read_committed/unconsistent_read_spec.rb](spec/read_committed/unconsistent_read_spec.rb) - This spec demonstrates unconsistent reads at the read committed isolation level.
* [spec/read_committed/lost_update_read_spec.rb](spec/read_committed/lost_update_read_spec.rb) - This spec demonstrates lost update problem at the read committed isolation level.
