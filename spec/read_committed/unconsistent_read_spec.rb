require_relative '../spec_helper'

describe 'Postgresql :read_committed transaction isolation level - unconsistent read problem' do
  let(:isolation) { :read_committed }

  context 'When we start two competitive transactions' do
    def first_transaction
      transaction(isolation:) do
        exec_sql <<~SQL
          UPDATE accounts SET amount = amount - 100 WHERE id = 2;
        SQL

        sleep 1

        exec_sql <<~SQL
          UPDATE accounts SET amount = amount + 100 WHERE id = 3;
        SQL
      end
    end

    def second_transaction
      result1 = nil
      result2 = nil
      ActiveRecord::Base.transaction(isolation:) do
        result1 = exec_sql <<~SQL
          SELECT amount FROM accounts WHERE id = 2;
        SQL

        sleep 2

        result2 = exec_sql <<~SQL
          SELECT amount FROM accounts WHERE id = 3;
        SQL
      end

      Thread.current[:result] = result1.first['amount'] + result2.first['amount']
    end

    it_behaves_like 'Shows the current transaction isolation level'

    it 'The second transaction reads the state of the second account and sees a new value' do
      thread1, thread2 = initialize_threads
      execute_concurrent_queries(thread1, thread2)

      expect(thread2.value).to eq(1100)
    end
  end
end
