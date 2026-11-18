class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAIL_FROM", "ひるどき <registration@example.test>") }
  layout "mailer"
end
