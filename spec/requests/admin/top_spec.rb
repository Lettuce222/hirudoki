require "rails_helper"

RSpec.describe Admin::TopController, type: :request do
  include Devise::Test::IntegrationHelpers

  it "未ログインでは管理画面を開けない" do
    get admin_root_path
    expect(response).to redirect_to(new_administrator_session_path)
  end

  it "利用者としてログインしても管理画面を開けない" do
    sign_in create(:user)
    get admin_root_path
    expect(response).to redirect_to(new_administrator_session_path)
  end
end
