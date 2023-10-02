shared_examples 'Shows the current transaction isolation level' do
  before do
    exec_sql <<~SQL
      BEGIN TRANSACTION ISOLATION LEVEL #{isolation.to_s.gsub(/_/, ' ').upcase};
    SQL
  end

  after { exec_sql 'COMMIT' }

  it do
    result = exec_sql <<~SQL
      SHOW transaction_isolation;
    SQL

    expect(result.first['transaction_isolation']).to eq isolation.to_s.gsub(/_/, ' ').downcase
  end
end
