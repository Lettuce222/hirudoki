class ApplicationController < ActionController::Base
  default_form_builder Railsui::FormBuilder

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def require_user
    redirect_to root_path unless user_signed_in?
  end
end
