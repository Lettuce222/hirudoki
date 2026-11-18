require "capybara/selenium/driver"

module ChromeStorageReset
  private

  def execute_cdp(command, params = {})
    return super unless command == "Storage.clearDataForOrigin" && params[:origin] == "*"

    # Chrome 158 はワイルドカードを拒むため、Cookie と Rails のオリジンのデータを個別に消去する。
    storage_types = params.fetch(:storageTypes).split(",")
    super("Storage.clearCookies") if storage_types.delete("cookies")
    return if storage_types.empty?

    super(command, origin: @session.server_url, storageTypes: storage_types.join(","))
  end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeStorageReset)
