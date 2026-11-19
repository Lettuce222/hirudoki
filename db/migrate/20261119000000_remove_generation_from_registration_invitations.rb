class RemoveGenerationFromRegistrationInvitations < ActiveRecord::Migration[8.1]
  def change
    remove_column :registration_invitations, :generation, :integer, null: false, default: 0
  end
end
