require 'rspec'
require 'active_support/logger'

include ActiveRecord::TestFixtures

RSpec.configure do |config|
  config.use_transactional_tests = false
end
