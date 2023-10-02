module TransactionHelper
  def transaction(isolation: :read_committed, &block)
    result = nil
    ActiveRecord::Base.transaction(isolation:) do
      result = block.call
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
