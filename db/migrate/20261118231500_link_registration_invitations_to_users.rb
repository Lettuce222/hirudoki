class LinkRegistrationInvitationsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :registration_invitations, :user, null: true, foreign_key: true, index: { unique: true }
  end
end
