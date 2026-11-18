class RegistrationMailer < ApplicationMailer
  def confirmation(invitation)
    @url = new_registration_url(token: invitation.signed_link)
    mail(to: invitation.email, subject: "ひるどきの利用者登録")
  end
end
