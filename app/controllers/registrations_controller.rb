class RegistrationsController < ApplicationController
  before_action :protect_registration_link

  def new
    invitation = RegistrationInvitation.from_link(params[:token])
    return redirect_to_new_registration_invitation unless invitation

    @user = User.new(email: invitation.email)
  end

  def create
    @user = RegistrationInvitation.register!(params[:token], registration_params)
    reset_session
    sign_in(:user, @user)
    redirect_to profile_path, notice: "利用者登録が完了しました。", status: :see_other
  rescue ActiveRecord::RecordInvalid => error
    @user = error.record
    render :new, status: :unprocessable_content
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordNotUnique
    redirect_to_new_registration_invitation
  end

  private

  def registration_params
    params.expect(user: [ :name, :phone, :password, :password_confirmation ])
  end

  def protect_registration_link
    no_store
    response.headers["Referrer-Policy"] = "no-referrer"
  end

  def redirect_to_new_registration_invitation
    redirect_to new_registration_invitation_path, alert: "リンクが無効です。確認メールを再度お申し込みください。", status: :see_other
  end
end
