require "rails_helper"

RSpec.describe "管理者のシード", type: :model do
  it "認証情報を指定してシードを繰り返すと、同じ管理者が登録時のパスワードで認証できる" do
    stub_const("ENV", ENV.to_h.merge("SEED_ADMIN_EMAIL" => "ADMIN@example.test", "SEED_ADMIN_PASSWORD" => "before-change", "SEED_ADMIN_NAME" => "管理担当"))
    expect { Rails.application.load_seed }.to change(Administrator, :count).by(1)
    administrator = Administrator.find_by!(email: "admin@example.test")
    expect(administrator.name).to eq("管理担当")
    expect(administrator.encrypted_password).not_to eq("before-change")
    ENV["SEED_ADMIN_PASSWORD"] = "after-change"
    expect { Rails.application.load_seed }.not_to change(Administrator, :count)
    expect(administrator.reload.valid_password?("before-change")).to be(true)
  end

  it "氏名と一意のメールアドレスを必須とする" do
    administrator = Administrator.create!(email: "admin@example.test", name: "管理担当", password: "test-password")
    expect(Administrator.new(email: administrator.email.upcase, name: "別担当", password: "test-password")).not_to be_valid
    expect(Administrator.new(email: "other@example.test", password: "test-password")).not_to be_valid
  end
end
