class RegistrationInvitation < ApplicationRecord
  RESEND_INTERVAL = 1.minute
  LINK_LIFETIME = 30.minutes

  belongs_to :user, optional: true
  scope :pending, -> { where(user_id: nil) }

  normalizes :email, with: ->(value) { value.strip.downcase }
  validates :email, presence: true, format: { with: Devise.email_regexp }, length: { maximum: 254 }
  generates_token_for(:registration, expires_in: LINK_LIFETIME) { generation }

  def self.deliver_to!(address)
    candidate = new(email: address)
    candidate.validate!
    return candidate if User.exists?(email: candidate.email)

    transaction do
      # 初回の申請が重なっても、再送時と同じ行をロックする。
      insert_all([ { email: candidate.email } ], unique_by: :email)
      invitation = lock.find_by!(email: candidate.email)
      unless invitation.user_id? || invitation.sent_at&.after?(RESEND_INTERVAL.ago)
        invitation.update!(generation: invitation.generation + 1, sent_at: Time.current)
        RegistrationMailer.confirmation(invitation).deliver_now
      end
      invitation
    end
  end

  def self.from_link(token)
    pending.find_by_token_for(:registration, token) if token.is_a?(String) && token.present?
  end

  def signed_link
    generate_token_for(:registration)
  end

  def self.register!(token, details)
    raise ActiveRecord::RecordNotFound unless token.is_a?(String)

    transaction do
      invitation = pending.lock.find_by_token_for(:registration, token) || raise(ActiveRecord::RecordNotFound)
      user = User.create!(details.merge(email: invitation.email))
      invitation.update!(user: user)
      user
    end
  end
end
