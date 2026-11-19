require "devise/orm/active_record"

Devise.setup do |config|
  config.stretches = 1 if Rails.env.test?
end
