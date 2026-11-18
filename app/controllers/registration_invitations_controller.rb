class RegistrationInvitationsController < ApplicationController
  rate_limit to: 12, within: 1.hour, only: :create, with: -> {
    @error = "しばらく時間をおいてから、もう一度お試しください。"
    render :new, status: :too_many_requests
  }

  def new
  end

  def create
    invitation = RegistrationInvitation.deliver_to!(params[:email].to_s)
    session[:registration_email] = invitation.email
    redirect_to registration_invitation_path, status: :see_other
  rescue ActiveRecord::RecordInvalid
    @error = "有効なメールアドレスを入力してください。"
    render :new, status: :unprocessable_content
  rescue Net::SMTPError, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError
    @error = "確認メールを送信できませんでした。時間をおいてもう一度お試しください。"
    render :new, status: :service_unavailable
  end

  def show
    @email = session[:registration_email]
    redirect_to new_registration_invitation_path unless @email
  end
end
