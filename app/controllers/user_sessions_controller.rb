class UserSessionsController < Devise::SessionsController
  private

  def after_sign_in_path_for(_user)
    daily_menus_path
  end
end
