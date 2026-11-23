require "devise/orm/active_record"

Devise.setup do |config|
  config.sign_out_all_scopes = false
  config.stretches = 1 if Rails.env.test?
  config.responder.error_status = :unprocessable_content
  config.responder.redirect_status = :see_other
end
