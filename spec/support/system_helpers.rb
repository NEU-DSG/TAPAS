module SystemHelpers
  include Warden::Test::Helpers

  def sign_in_as(user)
    login_as(user, scope: :user)
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system

  config.before(:each, type: :system) do
    Warden.test_mode!
  end

  config.after(:each, type: :system) do
    Warden.test_reset!
  end
end
