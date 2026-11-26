module RecurringOrderSettingsHelper
  def weekday_name(weekday)
    t("date.day_names").fetch(weekday)
  end

  def weekday_options
    RecurringOrderSetting::WEEKDAYS.map { |weekday| [ weekday_name(weekday), weekday ] }
  end

  def delivery_area_options(areas)
    areas.map do |area|
      name = area.active? ? area.name : "#{area.name}（受付終了）"
      [ name, area.id ]
    end
  end
end
