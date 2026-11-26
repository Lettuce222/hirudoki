require "rails_helper"

RSpec.describe RecurringOrderSetting do
  it "登録できる曜日は月曜から金曜だけで、利用者ごとに1曜日1件に制限する" do
    setting = create(:recurring_order_setting, weekday: 1)

    expect(build(:recurring_order_setting, user: setting.user, weekday: 1)).not_to be_valid
    expect(build(:recurring_order_setting, user: setting.user, weekday: 5)).to be_valid
    expect(build(:recurring_order_setting, weekday: 0)).not_to be_valid
    expect(build(:recurring_order_setting, weekday: 6)).not_to be_valid
    expect do
      RecurringOrderSetting.insert_all!([ setting.attributes.except("id") ])
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "4タイプのいずれか、1〜3個、配達先住所を設定する" do
    expect(build(:recurring_order_setting, bento_type: "和食", quantity: 3)).to be_valid
    expect(build(:recurring_order_setting, bento_type: "日替わり")).not_to be_valid
    expect(build(:recurring_order_setting, quantity: 0)).not_to be_valid
    expect(build(:recurring_order_setting, quantity: 4)).not_to be_valid
    expect(build(:recurring_order_setting, delivery_address: "")).not_to be_valid
  end

  it "無効なエリアを新たに選択できず、参照済みのエリアは無効化できる" do
    area = create(:delivery_area)
    setting = create(:recurring_order_setting, delivery_area: area)
    area.update!(active: false)

    expect(build(:recurring_order_setting, delivery_area: area)).not_to be_valid
    expect(setting.update(active: false)).to be(true)
    expect(area.destroy).to be(false)
  end
end
