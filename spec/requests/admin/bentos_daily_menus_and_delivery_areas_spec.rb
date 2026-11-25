require "rails_helper"

RSpec.describe "管理者の弁当・日別献立・配達エリア管理", type: :request do
  let(:administrator) { create(:administrator) }
  let(:bento) { create(:bento, name: "焼き鮭", price: 500) }
  let(:served_on) { Date.new(2028, 2, 29) }
  let(:menu_attributes) { { bento_id: bento.id, served_on:, capacity: 3 } }
  let(:area_attributes) { { name: "本町", postal_code: "0012345" } }

  def log_in
    post administrator_session_path, params: { administrator: { email: administrator.email, password: administrator.password } }
  end

  it "未ログインの閲覧・登録や一般利用者の変更を拒否する" do
    get "/admin/bentos"
    expect(response).to redirect_to(new_administrator_session_path)
    expect { post "/admin/delivery_areas", params: { delivery_area: area_attributes } }.not_to change(DeliveryArea, :count)
    user = create(:user)
    post user_session_path, params: { user: { email: user.email, password: user.password } }
    patch "/admin/bentos/#{bento.id}", params: { bento: { price: 3 } }
    expect(response).to redirect_to(new_administrator_session_path)
    expect(bento.reload.price).to eq(500)
  end

  it "同日同タイプの登録と参照中の弁当削除を拒否し、未参照にすると削除できる" do
    log_in
    post admin_daily_menus_path, params: { daily_menu: menu_attributes }
    menu = DailyMenu.find_by!(served_on:)
    expect { post admin_daily_menus_path, params: { daily_menu: menu_attributes } }.not_to change(DailyMenu, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("同じ提供日")
    expect { delete admin_bento_path(bento) }.not_to change(Bento, :count)
    expect(response).to redirect_to(admin_bentos_path)
    follow_redirect!
    expect(response.body).to include("削除できません")
    patch admin_daily_menu_path(menu), params: { daily_menu: { capacity: 0 } }
    expect(menu.reload.capacity).to be_zero
    expect { delete admin_daily_menu_path(menu) }.to change(DailyMenu, :count).by(-1)
    expect { delete admin_bento_path(bento) }.to change(Bento, :count).by(-1)
  end

  it "郵便番号の入力エラーを修正して保存し、未参照エリアを削除できる" do
    log_in
    post admin_delivery_areas_path, params: { delivery_area: area_attributes.merge(postal_code: "abc") }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("郵便番号")
    post admin_delivery_areas_path, params: { delivery_area: area_attributes }
    area = DeliveryArea.find_by!(postal_code: "0012345")
    expect { delete admin_delivery_area_path(area) }.to change(DeliveryArea, :count).by(-1)
  end

  it "画像以外の添付を拒否し、登録済みの弁当画像を保持する" do
    log_in
    bento.image.attach(io: Rails.root.join("app/assets/images/salmon-bento.jpg").open("rb"), filename: "bento.jpg", content_type: "image/jpeg")
    original = bento.image.blob
    upload = Rack::Test::UploadedFile.new(Rails.root.join("README.md"), "text/plain")
    patch admin_bento_path(bento), params: { bento: { image: upload } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("画像")
    expect(response.body).to include("焼き鮭の登録画像")
    expect(bento.reload.image.blob).to eq(original)
  end
end
