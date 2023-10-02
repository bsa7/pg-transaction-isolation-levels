require_relative '../spec_helper'

describe 'Postgresql :read_committed transaction isolation level - dirty read problem' do
  let(:isolation) { :read_committed }

  context 'When we start two competitive transactions' do
    def second_transaction
      transaction(isolation:) do
        exec_sql <<~SQL
          SELECT amount FROM accounts WHERE client = 'alice';
        SQL
      end
    end

    it_behaves_like 'Shows the current transaction isolation level' do
      let(:expected_isolation_level) { 'read committed' }
    end

    it 'The second transaction does not see the changes made by the first transaction' do
      thread1, thread2 = initialize_threads
      execute_concurrent_queries(thread1, thread2)

      expect(amount(thread1)).to eq(800)
      expect(amount(thread2)).to eq(1000)
    end
  end
end
