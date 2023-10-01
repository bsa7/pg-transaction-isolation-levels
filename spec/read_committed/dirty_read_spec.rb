require 'active_record'
require 'rspec'
require_relative '../spec_helper'
require_relative '../shared_examples'
require_relative './read_committed_helper'

describe 'Postgresql :read_committed transaction isolation level' do
  context 'When we start two competitive transactions' do
    include ReadCommittedHelper

    def second_transaction
      result = nil
      ActiveRecord::Base.transaction do
        result = exec_sql <<~SQL
          SELECT amount FROM accounts WHERE client = 'alice';
        SQL
      end

      Thread.current[:result] = result.first
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
