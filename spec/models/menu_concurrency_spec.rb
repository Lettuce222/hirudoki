require "rails_helper"
require "timeout"

RSpec.describe "献立の同時更新", type: :model do
  self.use_transactional_tests = false

  let(:served_on) { Date.new(2026, 12, 3) }
  let!(:first_bento) { create(:bento, bento_type: "和食") }
  let!(:second_bento) { create(:bento, bento_type: "和食") }

  after do
    ids = [ first_bento.id, second_bento.id ]
    DailyMenu.where(bento_id: ids).delete_all
    Bento.where(id: ids).delete_all
  end

  # 先行トランザクションを開いたまま、別接続が保存を完了するかロックを待つまで進める。
  def race(first_write, &second_write)
    worker = nil
    backend = Queue.new
    DailyMenu.transaction do
      first_write.call
      worker = Thread.new do
        DailyMenu.connection_pool.with_connection do |connection|
          backend << connection.select_value("SELECT pg_backend_pid()")
          second_write.call
        end
      end
      Timeout.timeout(10) do
        pid = backend.pop
        while worker.alive? && !DailyMenu.connection.select_value("SELECT pg_backend_pid() = ANY(pg_blocking_pids(#{Integer(pid)}))")
          sleep 0.01
        end
      end
    end
    worker.value
  ensure
    worker&.join
  end

  it "別の弁当でも、同じ日・同じタイプの同時登録は片方だけ保存する" do
    accepted = race(-> { create(:daily_menu, served_on:, bento: first_bento) }) do
      build(:daily_menu, served_on:, bento: second_bento).save
    end
    expect(accepted).to be(false)
    expect(DailyMenu.where(served_on:, bento_id: [ first_bento.id, second_bento.id ]).count).to eq(1)
  end

  it "献立の登録中に、同日の別の弁当を同じタイプに変更できない" do
    second_bento.update!(bento_type: "洋食")
    create(:daily_menu, served_on:, bento: second_bento)
    accepted = race(-> { create(:daily_menu, served_on:, bento: first_bento) }) do
      second_bento.update(bento_type: "和食")
    end
    expect(accepted).to be(false)
    expect(second_bento.reload.bento_type).to eq("洋食")
  end

  it "弁当タイプの変更中に、その変更と重複する献立を保存できない" do
    second_bento.update!(bento_type: "洋食")
    create(:daily_menu, served_on:, bento: second_bento)
    accepted = race(-> { second_bento.update!(bento_type: "和食") }) do
      build(:daily_menu, served_on:, bento: first_bento).save
    end
    expect(accepted).to be(false)
    expect(DailyMenu.exists?(served_on:, bento: first_bento)).to be(false)
  end
end
