require "rails_helper"

RSpec.describe "管理者のルーティング", type: :routing do
  it "管理者の登録ルートは公開されていない" do
    expect(get: "/admin/sign_up").not_to be_routable
    expect(post: "/admin").not_to be_routable
  end
end
