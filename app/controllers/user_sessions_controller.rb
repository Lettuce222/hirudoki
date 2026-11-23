class UserSessionsController < Devise::SessionsController
  private

  def after_sign_in_path_for(_user)
    profile_path
  end
end
