require "rails_helper"

RSpec.describe "Home", type: :system do
  viewports = [ [ "desktop", 1280, 900 ], [ "mobile", 390, 844 ] ]

  viewports.each do |name, width, height|
    it "shows an accessible home page on #{name}" do
      page.current_window.resize_to(width, height)
      visit root_path

      expect(page).to have_css("h1", text: "ひるどき")
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :wcag22aa)
    end
  end
end
