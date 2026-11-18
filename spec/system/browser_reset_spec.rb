require "rails_helper"

RSpec.describe "Browser reset", type: :system do
  it "clears cookies and local storage while reusing Chrome" do
    visit root_path
    browser = page.driver.browser
    browser.manage.add_cookie(name: "reset_probe", value: "present")
    page.execute_script("localStorage.setItem('reset_probe', 'present')")

    page.reset!
    visit root_path

    expect(page.driver.browser).to equal(browser)
    expect(browser.manage.all_cookies.pluck(:name)).not_to include("reset_probe")
    expect(page.evaluate_script("localStorage.getItem('reset_probe')")).to be_nil
  end
end
