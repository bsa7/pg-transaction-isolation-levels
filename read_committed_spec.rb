require 'active_record'
require 'rspec'

require_relative './pg_shared_context'

describe 'Postgresql :read_committed transaction isolation level' do
  include_context 'Database initialization and connection test'

  context 'First, lets fill out the accounts table.' do
    before do
      populate_accounts_table
    end

    it 'Returns the amount in Bobs accounts' do
      result = exec_sql <<~SQL
        SELECT SUM(amount) FROM accounts WHERE client = 'bob' GROUP BY client
      SQL

      expect(result.first['sum']).to eq 1000
    end

    context 'When the transaction is started' do
      before do
        exec_sql <<~SQL
          BEGIN;
        SQL
      end

      after do
        exec_sql <<~SQL
          COMMIT;
        SQL
      end

      it 'Shows the current transaction isolation level' do
        result = exec_sql <<~SQL
          SHOW transaction_isolation;
        SQL

        expect(result.first['transaction_isolation']).to eq 'read committed'
      end

      it 'Shows the current default transaction isolation level' do
        result = exec_sql <<~SQL
          SHOW default_transaction_isolation;
        SQL

        expect(result.first['default_transaction_isolation']).to eq 'read committed'
      end
    end
  end
end
