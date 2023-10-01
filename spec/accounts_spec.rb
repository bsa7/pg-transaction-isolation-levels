require 'active_record'
require 'rspec'
require_relative './spec_helper.rb'

describe 'Postgresql - verifiy that database and accounts table is working as expected' do
  it 'Returns list of database tables' do
    expect(::ActiveRecord::Base.connection.tables).to be_present
  end

  context 'First, lets fill out the accounts table.' do
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

      it 'Shows the current default transaction isolation level' do
        result = exec_sql <<~SQL
          SHOW default_transaction_isolation;
        SQL

        expect(result.first['default_transaction_isolation']).to eq 'read committed'
      end

      context 'When we withdraw funds from the account in an open transaction' do
        before do
          exec_sql <<~SQL
            UPDATE accounts SET amount = amount - 200 WHERE id = 1;
          SQL
        end

        context 'But do not record the changes' do
          it 'The transaction always sees its own changes' do
            result = exec_sql <<~SQL
              SELECT amount FROM accounts WHERE client = 'alice'
            SQL

            expect(result.first['amount']).to eq 800
          end
        end
      end
    end
  end
end
