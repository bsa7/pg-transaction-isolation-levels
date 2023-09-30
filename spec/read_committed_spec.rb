require 'active_record'
require 'rspec'
require_relative './pg_shared_context'

describe 'Postgresql :read_committed transaction isolation level' do
  include_context 'Database initialization'

  before do
    populate_accounts_table
  end

  context 'When we start two competitive transactions' do
    def first_transaction
      result = nil
      ActiveRecord::Base.transaction do
        result = exec_sql <<~SQL
          UPDATE accounts SET amount = amount - 200 WHERE id = 1;
          SELECT amount FROM accounts WHERE client = 'alice'
        SQL

        sleep 1
      end

      Thread.current[:result] = result.first
    end

    def second_transaction
      result = nil
      ActiveRecord::Base.transaction do
        result = exec_sql <<~SQL
          SELECT amount FROM accounts WHERE client = 'alice';
        SQL
      end

      Thread.current[:result] = result.first
    end

    it 'The second transaction does not see the changes made by the first transaction', use_transactions: false do
      thread1 = Thread.new { first_transaction }
      thread2 = Thread.new { second_transaction }
      [thread1, thread2].each(&:join)

      expect(thread1.value['amount']).to eq 800
      expect(thread2.value['amount']).to eq 1000
    end
  end
end
