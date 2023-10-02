require_relative '../spec_helper'

describe 'Postgresql :read_committed transaction isolation level - lost update problem' do
  let(:isolation) { :read_committed }

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

    it 'The result of the second transaction will not be saved' do
      thread1, thread2 = initialize_threads
      execute_concurrent_queries(thread1, thread2)
      real_amount = exec_sql <<~SQL
        SELECT amount FROM accounts WHERE id = 1;
      SQL

      expect(amount(thread1)).to eq(1101)
      expect(amount(thread2)).to eq(1102)
      expect(real_amount.first['amount']).to eq(1101)
    end
  end
end
