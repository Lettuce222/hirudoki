require "rails_helper"

RSpec.describe DeliveryArea, type: :model do
  it "7桁の郵便番号を先頭のゼロも含めて保存し、既定で有効にする" do
    area = create(:delivery_area, postal_code: "0010000")
    expect(area.reload.postal_code).to eq("0010000")
    expect(area).to be_active
  end

  it "名前の欠落、桁数や形式が異なる郵便番号、郵便番号の重複を拒む" do
    create(:delivery_area, postal_code: "1000005")
    expect(build(:delivery_area, name: "")).not_to be_valid
    %w[100000 10000000 100-0005 100000a 1000005].each do |code|
      expect(build(:delivery_area, postal_code: code)).not_to be_valid
    end
  end
end
