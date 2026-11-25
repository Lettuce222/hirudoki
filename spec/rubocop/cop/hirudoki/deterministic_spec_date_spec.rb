require "rubocop"
require "rubocop/rspec/support"
require_relative "../../../../lib/rubocop/cop/hirudoki/deterministic_spec_date"

RSpec.describe RuboCop::Cop::Hirudoki::DeterministicSpecDate, :config do
  let(:message) { "Use a fixed date or read the clock inside travel_to with an explicit reference time." }

  it "specの入力に実行日や現在からの相対日付を使うと指摘する" do
    expect_offense(<<~RUBY)
      create(:daily_menu, served_on: Date.current)
                                     ^^^^^^^^^^^^ #{message}
      fill_in "提供日", with: 2.days.from_now.to_date
                           ^^^^^^^^^^^^^^^ #{message}
    RUBY
  end

  it "時計を固定する前に評価する基準日時も検査する" do
    expect_offense(<<~RUBY)
      travel_to(Time.current) { Date.current }
                ^^^^^^^^^^^^ #{message}
      freeze_time { Date.today }
                    ^^^^^^^^^^ #{message}
    RUBY
  end

  it "無作為なサンプル日付と単位を省いた経過時間を指摘する" do
    expect_offense(<<~RUBY)
      Faker::Date.forward(days: 5)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use a fixed date for example data.
      travel 59
      ^^^^^^^^^ Express elapsed time with its unit, such as 59.seconds.
    RUBY
  end

  it "固定値からの計算と固定した時計の参照を許可する" do
    expect_no_offenses(<<~RUBY)
      sequence(:served_on) { |n| Date.new(2028, 2, 28) + n }
      travel_to(Time.zone.local(2028, 2, 29, 9, 59)) do
        travel 59.seconds
        expect(Date.current).to eq(Date.new(2028, 2, 29))
        expect(2.days.from_now).to be > Time.current
      end
      freeze_time(Date.new(2028, 3, 1)) { Time.zone.now }
      2.days.ago(Date.new(2028, 2, 29))
    RUBY
  end
end
