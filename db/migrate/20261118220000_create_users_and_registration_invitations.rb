class CreateUsersAndRegistrationInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false, index: { unique: true }
      t.string :encrypted_password, null: false
      t.string :phone, null: false
      t.timestamps
    end

    create_table :registration_invitations do |t|
      t.string :email, null: false, index: { unique: true }
      t.integer :generation, null: false, default: 0
      t.datetime :sent_at
      t.timestamps
    end
  end
end
