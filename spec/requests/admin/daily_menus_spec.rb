require "rails_helper"

RSpec.describe Admin::DailyMenusController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:served_on) { Date.new(2028, 2, 29) }

  before { sign_in create(:administrator) }

  it "同じ提供日に同タイプの献立を重複登録できない" do
    bento = create(:bento)
    attributes = { bento_id: bento.id, served_on:, capacity: 3 }

    expect { post admin_daily_menus_path, params: { daily_menu: attributes } }.to change(DailyMenu, :count).by(1)
    expect { post admin_daily_menus_path, params: { daily_menu: attributes } }.not_to change(DailyMenu, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("同じ提供日")
  end

  it "献立の提供数上限を0に変更できる" do
    menu = create(:daily_menu)

    patch admin_daily_menu_path(menu), params: { daily_menu: { capacity: 0 } }

    expect(menu.reload.capacity).to be_zero
  end

  it "注文が参照していない献立は削除できる" do
    menu = create(:daily_menu)

    expect { delete admin_daily_menu_path(menu) }.to change(DailyMenu, :count).by(-1)
  end

  it "キャンセル済み注文が参照する献立は削除できない" do
    menu = create(:daily_menu, served_on:)
    travel_to(Time.utc(2028, 2, 28)) do
      create(:order, daily_menu: menu).cancelled!
    end

    expect { delete admin_daily_menu_path(menu) }.not_to change(DailyMenu, :count)
    expect(response).to redirect_to(admin_daily_menus_path)
    follow_redirect!
    expect(response.body).to include("注文履歴があるため削除できません。", "注文一覧で提供日と弁当名を確認してください。")
  end
end
