shared_examples 'Shows the current transaction isolation level' do
  it do
    result = exec_sql <<~SQL
      SHOW transaction_isolation;
    SQL

    expect(result.first['transaction_isolation']).to eq expected_isolation_level
  end
end
