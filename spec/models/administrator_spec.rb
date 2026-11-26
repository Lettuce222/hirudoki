require "rails_helper"

RSpec.describe Administrator, type: :model do
  it "氏名と一意のメールアドレスを必須とする" do
    administrator = create(:administrator)
    expect(build(:administrator, email: administrator.email.upcase)).not_to be_valid
    expect(build(:administrator, name: nil)).not_to be_valid
  end
end
