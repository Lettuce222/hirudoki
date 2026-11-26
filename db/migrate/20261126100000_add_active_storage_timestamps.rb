class AddActiveStorageTimestamps < ActiveRecord::Migration[8.1]
  def change
    add_column :active_storage_attachments, :updated_at, :datetime, null: false, default: -> { "CURRENT_TIMESTAMP" }
    add_column :active_storage_blobs, :updated_at, :datetime, null: false, default: -> { "CURRENT_TIMESTAMP" }
    add_timestamps :active_storage_variant_records, null: false, default: -> { "CURRENT_TIMESTAMP" }

    reversible do |direction|
      direction.up do
        execute "UPDATE active_storage_attachments SET updated_at = created_at"
        execute "UPDATE active_storage_blobs SET updated_at = created_at"
      end
    end
  end
end
