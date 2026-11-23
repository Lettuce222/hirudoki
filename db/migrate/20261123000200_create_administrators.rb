class CreateAdministrators < ActiveRecord::Migration[8.1]
  def change
    create_table :administrators do |t|
      t.string :name, null: false
      t.string :email, null: false, index: { unique: true }
      t.string :encrypted_password, null: false
      t.timestamps
    end
  end
end
