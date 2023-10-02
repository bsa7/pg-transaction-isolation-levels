module TransactionHelper
  def first_transaction
    transaction(pause: 1) do
      exec_sql <<~SQL
        UPDATE accounts SET amount = amount - 200 WHERE id = 1;
        SELECT amount FROM accounts WHERE client = 'alice'
      SQL
    end
  end

  def transaction(isolation: :read_committed, pause: nil, &block)
    result = nil
    ActiveRecord::Base.transaction(isolation:) do
      result = block.call
      sleep(pause) unless pause.nil?
    end

    Thread.current[:result] = result
  end

  def initialize_threads
    [
      Thread.new { first_transaction },
      Thread.new { second_transaction }
    ]
  end

  def amount(thread)
    thread.value.first['amount']
  end

  def execute_concurrent_queries(*threads)
    threads.each(&:join)
  end
end
