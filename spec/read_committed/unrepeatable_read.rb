require_relative '../spec_helper'

describe 'Postgresql :read_committed transaction isolation level - unrepeatable read problem' do
  let(:isolation) { :read_committed }

  context 'When we start two competitive transactions' do
    def second_transaction
      transaction(isolation:) do
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
    end

    it_behaves_like 'Shows the current transaction isolation level'

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
