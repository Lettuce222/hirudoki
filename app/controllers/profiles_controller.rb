class ProfilesController < ApplicationController
  before_action :no_store
  before_action :require_user

  def show
    @orders = current_user.orders.desc_by_created_at.preload(:delivery_area, daily_menu: :bento)
  end
end
