module SessionHelpers
  # Logs in through the real SessionsController#create, the same way a
  # browser would, so request specs exercise the actual
  # require_authentication/resume_session path (and its signed session
  # cookie) rather than stubbing around it. Assumes the default factory
  # password unless a different one was set.
  def sign_in_as(user, password: "password123")
    post session_path, params: { email_address: user.email_address, password: password }
  end
end

RSpec.configure do |config|
  config.include SessionHelpers, type: :request
end
