class ProfilesController < ApplicationController
  def show
    no_store
    redirect_to root_path unless user_signed_in?
  end
end
