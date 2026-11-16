# Run only from an authenticated server shell:
#   bin/rails runner script/storage-smoke.rb
# Repeated runs reuse the same database record and verify persistent file bytes.
require "digest"
require "json"

image = Rails.root.join("public/icon.png")
blob = ActiveStorage::Blob.find_by(filename: "walking-skeleton-probe.png")
unless blob
  blob = File.open(image) do |file|
    ActiveStorage::Blob.create_and_upload!(
      io: file, filename: "walking-skeleton-probe.png", content_type: "image/png"
    )
  end
end

expected = Digest::SHA256.file(image).hexdigest
actual = Digest::SHA256.hexdigest(blob.download)
abort "Persistent image checksum mismatch" unless actual == expected

puts JSON.generate(
  database: ActiveRecord::Base.connection.select_value("SELECT current_database()"),
  blob_id: blob.id, key: blob.key, bytes: blob.byte_size, sha256: actual,
  image_path: Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
)
