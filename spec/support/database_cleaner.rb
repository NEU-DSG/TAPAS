RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do |example|
    # System specs run the browser in a separate thread; the transaction is not
    # visible across threads, so we use truncation to ensure committed data.
    strategy = example.metadata[:type] == :system ? :truncation : :transaction
    DatabaseCleaner.strategy = strategy
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
