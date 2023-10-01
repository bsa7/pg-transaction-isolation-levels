require 'active_record'
require 'rspec'
require_relative '../spec_helper'
require_relative '../shared_examples'
require_relative './read_committed_helper'

describe 'Postgresql :read_committed transaction isolation level - unrepeatable read problem' do
  context 'When we start two competitive transactions' do
    include ReadCommittedHelper

    def second_transaction
      result = nil
      ActiveRecord::Base.transaction do
        result = exec_sql <<~SQL
          SELECT amount FROM accounts WHERE client = 'alice';
        SQL

        sleep 2

        if result.first['amount'] >- 1000
          exec_sql <<~SQL
            UPDATE accounts SET amount = amount - 900 WHERE id = 1
          SQL
        end

        result = exec_sql <<~SQL
        SELECT amount FROM accounts WHERE client = 'alice';
      SQL

      end

      Thread.current[:result] = result.first
    end

    it_behaves_like 'Shows the current transaction isolation level' do
      let(:expected_isolation_level) { 'read committed' }
    end

    it 'During the time that elapses between check and update, other transactions may change the state of the record' do
      thread1, thread2 = initialize_threads
      execute_concurrent_queries(thread1, thread2)

      expect(amount(thread1)).to eq(800)
      expect(amount(thread2)).to eq(-100)
    end


    context 'If we add an integrity constraint to a amount column' do
      before do
        exec_sql <<~SQL
          ALTER TABLE accounts
            ADD CONSTRAINT positive_amount
            CHECK (amount >= 0);
        SQL
      end

      it 'The second transaction will not be able to save the data' do
        thread1, thread2 = initialize_threads
        expect { execute_concurrent_queries(thread1, thread2) }.to raise_error(ActiveRecord::StatementInvalid)
      end
    end
  end
end
