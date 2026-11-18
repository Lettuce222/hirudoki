require "rails_helper"

RSpec.describe "Home", type: :system do
  viewports = [ [ "desktop", 1280, 900 ], [ "mobile", 390, 844 ] ]

  viewports.each do |name, width, height|
    it "shows the application name on #{name}" do
      page.current_window.resize_to(width, height)
      visit root_path

      expect(page).to have_css("h1", text: "ひるどき")
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    end
  end
end
