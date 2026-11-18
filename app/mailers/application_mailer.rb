class ApplicationMailer < ActionMailer::Base
  default from: -> { Rails.env.production? ? ENV.fetch("MAIL_FROM") : "ひるどき <registration@example.test>" }
  layout "mailer"
end
