class RegistrationsController < ApplicationController
  before_action :load_invitation

  def new
    @user = User.new
  end

  def create
    @user = @invitation.register!(params[:token], params.expect(user: [ :name, :phone, :password, :password_confirmation ]))
    reset_session
    sign_in(:user, @user)
    redirect_to profile_path, notice: "利用者登録が完了しました。", status: :see_other
  rescue ActiveRecord::RecordInvalid => error
    @user = error.record
    render :new, status: :unprocessable_content
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordNotUnique
    expired_link
  end

  private

  def load_invitation
    no_store
    response.headers["Referrer-Policy"] = "no-referrer"
    @invitation = RegistrationInvitation.from_link(params[:token])
    expired_link unless @invitation
  end

  def expired_link
    redirect_to new_registration_invitation_path, alert: "リンクが無効です。確認メールを再度お申し込みください。", status: :see_other
  end
end
