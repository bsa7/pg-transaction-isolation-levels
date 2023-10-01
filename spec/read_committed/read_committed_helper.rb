module ReadCommittedHelper
  def first_transaction
    result = nil
    ActiveRecord::Base.transaction do
      result = exec_sql <<~SQL
        UPDATE accounts SET amount = amount - 200 WHERE id = 1;
        SELECT amount FROM accounts WHERE client = 'alice'
      SQL

      sleep 1
    end

    Thread.current[:result] = result.first
  end

  def initialize_threads
    [
      Thread.new { first_transaction },
      Thread.new { second_transaction }
    ]
  end

  def amount(thread)
    thread.value['amount']
  end

  def execute_concurrent_queries(*threads)
    threads.each(&:join)
  end
end
