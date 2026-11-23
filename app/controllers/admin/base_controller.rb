class Admin::BaseController < ApplicationController
  before_action :no_store
  before_action :authenticate_administrator!
end
