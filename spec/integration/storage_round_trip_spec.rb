require "rails_helper"

RSpec.describe "Active Storage round trip" do
  it "persists image metadata in PostgreSQL and reads the original bytes from storage" do
    image = Rails.root.join("public/icon.png")
    blob = File.open(image) do |file|
      ActiveStorage::Blob.create_and_upload!(io: file, filename: "probe.png", content_type: "image/png")
    end

    expect(ActiveStorage::Blob.find(blob.id).key).to eq(blob.key)
    expect(blob.download).to eq(File.binread(image))
  ensure
    blob&.purge
  end
end
