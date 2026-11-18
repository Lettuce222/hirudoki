class RegistrationInvitation < ApplicationRecord
  RESEND_INTERVAL = 1.minute
  LINK_LIFETIME = 30.minutes

  normalizes :email, with: ->(value) { value.strip.downcase }
  validates :email, presence: true, format: { with: Devise.email_regexp }, length: { maximum: 254 }
  generates_token_for(:registration, expires_in: LINK_LIFETIME) { generation }

  def self.deliver_to!(address)
    candidate = new(email: address)
    candidate.validate!
    transaction do
      # Concurrent first requests must acquire the same row lock as resends.
      insert_all([ { email: candidate.email } ], unique_by: :email)
      invitation = lock.find_by!(email: candidate.email)
      unless User.exists?(email: invitation.email) || invitation.sent_at&.after?(RESEND_INTERVAL.ago)
        invitation.update!(generation: invitation.generation + 1, sent_at: Time.current)
        RegistrationMailer.confirmation(invitation).deliver_now
      end
      invitation
    end
  end

  def self.from_link(token)
    find_by_token_for(:registration, token) if token.is_a?(String) && token.present?
  end

  def signed_link
    generate_token_for(:registration)
  end

  def register!(token, details)
    with_lock do
      raise ActiveRecord::RecordNotFound unless self.class.from_link(token) == self
      user = User.create!(details.merge(email: email))
      destroy!
      user
    end
  end
end
