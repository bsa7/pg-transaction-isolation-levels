require 'pry'
require 'rspec'
require 'active_support/logger'
require 'active_record'
require 'rspec'

require_relative './transaction_helper'

include ActiveRecord::TestFixtures
include TransactionHelper

def exec_sql(sql)
  ::ActiveRecord::Base.connection.execute(sql)
end

def populate_accounts_table
  exec_sql <<~SQL
    INSERT INTO accounts VALUES
    (1, 'alice', 1000.0),
    (2, 'bob', 100.0),
    (3, 'bob', 900.0)
  SQL
end

def initialize_table
  exec_sql <<~SQL
    DROP TABLE IF EXISTS accounts;
    CREATE TABLE accounts(
      id integer PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
      client text,
      amount numeric
    )
  SQL
end

def ci?
  ENV['GITHUB_ACTIONS'] == 'true'
end

def database_config
  ci? ? './config/database.ci.yml' : './config/database.yml'
end

Dir[Pathname.new('./spec/shared/**/*.rb')].sort.each { |f| require f }

configuration = YAML.load(ERB.new(File.read(database_config)).result)
ActiveRecord::Base.configurations = configuration
ActiveRecord::Base.establish_connection(:test)

RSpec.configure do |config|
  config.use_transactional_tests = false

  config.before(:each) do
    initialize_table
    populate_accounts_table
  end
end
