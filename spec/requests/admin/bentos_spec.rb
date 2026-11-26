require "rails_helper"

RSpec.describe Admin::BentosController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:bento) { create(:bento, name: "焼き鮭", price: 500) }

  context "未ログインの場合" do
    it "弁当一覧を閲覧できない" do
      get admin_bentos_path
      expect(response).to redirect_to(new_administrator_session_path)
    end
  end

  context "利用者としてログイン済みの場合" do
    before { sign_in create(:user) }

    it "弁当を変更できない" do
      patch admin_bento_path(bento), params: { bento: { price: 3 } }
      expect(response).to redirect_to(new_administrator_session_path)
      expect(bento.reload.price).to eq(500)
    end
  end

  context "管理者としてログイン済みの場合" do
    before { sign_in create(:administrator) }

    it "献立が参照する弁当は削除できない" do
      create(:daily_menu, bento:)

      expect { delete admin_bento_path(bento) }.not_to change(Bento, :count)
      expect(response).to redirect_to(admin_bentos_path)
      follow_redirect!
      expect(response.body).to include("削除できません")
    end

    it "キャンセル済み注文の献立が参照する弁当は削除できない" do
      menu = create(:daily_menu, bento:, served_on: Date.new(2028, 2, 29))
      travel_to(Time.utc(2028, 2, 28)) do
        create(:order, daily_menu: menu).cancelled!
      end

      expect { delete admin_bento_path(bento) }.not_to change(Bento, :count)
      expect(response).to redirect_to(admin_bentos_path)
    end

    it "献立が参照していない弁当は削除できる" do
      unreferenced_bento = create(:bento)

      expect { delete admin_bento_path(unreferenced_bento) }.to change(Bento, :count).by(-1)
    end

    it "画像以外の添付を拒否し、登録済みの弁当画像を保持する" do
      bento.image.attach(io: Rails.root.join("app/assets/images/salmon-bento.jpg").open("rb"), filename: "bento.jpg", content_type: "image/jpeg")
      original = bento.image.blob
      upload = Rack::Test::UploadedFile.new(Rails.root.join("README.md"), "text/plain")
      patch admin_bento_path(bento), params: { bento: { image: upload } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("画像")
      expect(response.body).to include("焼き鮭の登録画像")
      expect(bento.reload.image.blob).to eq(original)
    end

    it "弁当画像を保存して元のファイルを読み戻せる" do
      image = Rails.root.join("app/assets/images/salmon-bento.jpg")
      upload = Rack::Test::UploadedFile.new(image, "image/jpeg")

      patch admin_bento_path(bento), params: { bento: { image: upload } }

      attachment = bento.reload.image
      expect(response).to redirect_to(admin_bentos_path)
      expect(attachment.filename.to_s).to eq(image.basename.to_s)
      expect(attachment.download).to eq(File.binread(image))
    ensure
      attachment&.purge
    end
  end
end
