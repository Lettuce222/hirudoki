class Admin::SessionsController < Devise::SessionsController
  private

  def after_sign_in_path_for(_administrator)
    admin_root_path
  end

  def after_sign_out_path_for(_scope)
    new_administrator_session_path
  end
end
