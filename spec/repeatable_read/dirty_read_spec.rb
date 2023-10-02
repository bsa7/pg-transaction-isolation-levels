require_relative '../spec_helper'

describe 'Postgresql :repeatable_read transaction isolation level - dirty read problem' do
  let(:isolation) { :repeatable_read }

  context 'When we start two competitive transactions' do
    def first_transaction
      transaction(isolation:) do
        result = exec_sql <<~SQL
          UPDATE accounts SET amount = amount - 200 WHERE id = 1;
          SELECT amount FROM accounts WHERE client = 'alice'
        SQL

        sleep 1
        result
      end
    end

    def second_transaction
      transaction(isolation:) do
        exec_sql <<~SQL
          SELECT amount FROM accounts WHERE client = 'alice';
        SQL
      end
    end

    it_behaves_like 'Shows the current transaction isolation level'

    it 'The second transaction does not see the changes made by the first transaction' do
      thread1, thread2 = initialize_threads
      execute_concurrent_queries(thread1, thread2)

      expect(amount(thread1)).to eq(800)
      expect(amount(thread2)).to eq(1000) # <= Dirty Read is not possible on Repeatable Read isolation level
    end
  end
end
