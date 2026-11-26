credential = ->(key, local_value) { Rails.env.local? ? ENV.fetch(key, local_value) : ENV.fetch(key) }
admin_email = credential.call("SEED_ADMIN_EMAIL", "demo-admin@example.test").strip.downcase
admin_password = credential.call("SEED_ADMIN_PASSWORD", "hirudoki-local-admin")
user_email = credential.call("SEED_USER_EMAIL", "demo-user@example.test").strip.downcase
user_password = credential.call("SEED_USER_PASSWORD", "hirudoki-local-user")

first_day = Date.current
last_day = first_day + 14.days
menu_conflicts = []
bento_images = {}

# 同じ名前の弁当や登録済みの献立は保持し、確認用データだけを補う。
ApplicationRecord.transaction do
  Administrator.find_or_create_by!(email: admin_email) do |administrator|
    administrator.name = ENV.fetch("SEED_ADMIN_NAME", "ひるどき確認担当")
    administrator.password = admin_password
  end

  user = User.find_or_create_by!(email: user_email) do |record|
    record.name = "確認用利用者"
    record.phone = "09000000000"
    record.password = user_password
    record.password_confirmation = user_password
  end

  area_names = {
    "1000005" => "千代田区丸の内",
    "1010051" => "千代田区神田神保町",
    "1040031" => "中央区京橋"
  }
  areas = area_names.map do |postal_code, name|
    DeliveryArea.find_or_create_by!(postal_code:) { |area| area.name = name }
  end
  delivery_area = areas.find(&:active?)
  raise "確認用の配達エリアがすべて無効です。" unless delivery_area

  # 実在の個人や建物を示さない確認用の住所を使う。
  address = "#{area_names.fetch(delivery_area.postal_code)}1丁目 確認用住所"

  bentos = [
    [ "和食", "焼き鮭のり弁当", "焼き鮭とだし巻き卵、きんぴらをのせたのり弁当です。", 650, "salmon-bento.jpg" ],
    [ "和食", "さばの味噌煮弁当", "さばの味噌煮に小松菜のおひたしとひじき煮を添えました。", 720, "demo/miso-mackerel.jpg" ],
    [ "洋食", "デミグラスハンバーグ弁当", "ハンバーグにデミグラスソースをかけ、温野菜を添えました。", 800, "demo/demi-glace-hamburg.jpg" ],
    [ "洋食", "チキンのトマト煮弁当", "鶏もも肉と野菜をトマトで煮込み、バターライスを合わせました。", 750, "demo/tomato-chicken.jpg" ],
    [ "中華", "黒酢酢豚弁当", "豚肉と彩り野菜を黒酢あんで仕上げ、焼売を添えました。", 780, "demo/black-vinegar-pork.jpg" ],
    [ "中華", "麻婆茄子弁当", "なすと豚ひき肉の麻婆炒めに、春雨サラダを添えました。", 730, "demo/mapo-eggplant.jpg" ],
    [ "ヘルシー", "塩麹チキンと雑穀ごはん弁当", "塩麹で漬けた鶏むね肉を焼き、雑穀ごはんと蒸し野菜を合わせました。", 760, "demo/shio-koji-chicken.jpg" ],
    [ "ヘルシー", "豆腐つくねと根菜弁当", "豆腐つくねと根菜の煮物に、枝豆ごはんを合わせました。", 740, "demo/tofu-tsukune.jpg" ]
  ].map.with_index(1) do |(bento_type, name, description, price, image_file), display_order|
    bento = Bento.find_or_create_by!(name:, bento_type:) do |record|
      record.assign_attributes(description:, price:, display_order:)
    end
    bento_images[bento] = image_file
    bento
  end

  # 同じ提供日の同じタイプを探してから登録し、既存の弁当や上限を変えない。
  DailyMenu.with_schedule_lock do
    bentos.group_by(&:bento_type).each do |bento_type, entries|
      available = entries.select(&:on_sale?)
      raise "確認用の#{bento_type}の弁当がすべて非販売です。" if available.empty?

      (first_day..last_day).each_with_index do |served_on, day_index|
        menu = DailyMenu.with_bento_type(bento_type).find_by(served_on:)
        if menu
          menu_conflicts << "#{served_on}: #{bento_type}" unless menu.bento.on_sale?
        else
          bento = available.fetch(served_on.jd % available.size)
          DailyMenu.create!(served_on:, bento:, capacity: 12 + (day_index % 4) * 4)
        end
      end
    end
  end

  RecurringOrderSetting::WEEKDAYS.each do |weekday|
    user.recurring_order_settings.find_or_create_by!(weekday:) do |setting|
      setting.bento_type = Bento::BENTO_TYPES.fetch((weekday - 1) % Bento::BENTO_TYPES.size)
      setting.quantity = 1
      setting.delivery_area = delivery_area
      setting.delivery_address = address
    end
  end
end

# 既存の登録画像を尊重し、画像がない確認用弁当にだけ追加する。
bento_images.each do |bento, image_file|
  bento.with_lock do
    next if bento.image.attached?

    image_path = Rails.root.join("app/assets/images", image_file)
    bento.image = { io: StringIO.new(image_path.binread), filename: image_path.basename.to_s, content_type: "image/jpeg" }
    bento.save!
  end
end

puts "確認用データを準備しました（#{first_day}〜#{last_day}）。"
if menu_conflicts.any?
  warn "既存の非販売献立を保持した提供日とタイプがあります。利用者画面で確認する場合は管理画面で販売状態を確認してください。"
  menu_conflicts.each { |conflict| warn conflict }
end
