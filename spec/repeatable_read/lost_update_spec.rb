require_relative '../spec_helper'

describe 'Postgresql :repeatable_read transaction isolation level - lost update problem' do
  let(:isolation) { :repeatable_read }

  context 'When we start two competitive transactions' do
    def first_transaction
      transaction(isolation:) do
        result = exec_sql <<~SQL
          SELECT amount FROM accounts WHERE id = 1;
        SQL

        amount = result.first['amount']

        sleep 1

        exec_sql <<~SQL
          UPDATE accounts SET amount = #{amount} + 101 WHERE id = 1 RETURNING amount
        SQL
      end
    end

    def second_transaction
      transaction(isolation:) do
        result = exec_sql <<~SQL
          SELECT amount FROM accounts WHERE id = 1;
        SQL

        amount = result.first['amount']

        exec_sql <<~SQL
          UPDATE accounts SET amount = #{amount} + 102 WHERE id = 1 RETURNING amount
        SQL
      end
    end

    it_behaves_like 'Shows the current transaction isolation level'

    it 'The second transaction raised error' do
      thread1, thread2 = initialize_threads

      # <= Lost Update is not possible on Repeatable Read isolation level
      expect { execute_concurrent_queries(thread1, thread2) }.to raise_error(ActiveRecord::SerializationFailure)
    end
  end
end
