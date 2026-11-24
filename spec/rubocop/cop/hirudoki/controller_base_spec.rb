require "rubocop"
require "rubocop/rspec/support"
require_relative "../../../../lib/rubocop/cop/hirudoki/controller_base"

RSpec.describe RuboCop::Cop::Hirudoki::ControllerBase, :config do
  it "同じディレクトリに中間コントローラを挟むと指摘する" do
    expect_offense(<<~RUBY, "app/controllers/admin/bentos_controller.rb")
      class Admin::BentosController < Admin::CatalogController
                                      ^^^^^^^^^^^^^^^^^^^^^^^^ Inherit directly from Admin::BaseController.
      end
    RUBY
  end

  it "管理者用の基底クラスを飛ばすと指摘する" do
    expect_offense(<<~RUBY, "app/controllers/admin/bentos_controller.rb")
      class Admin::BentosController < ApplicationController
                                      ^^^^^^^^^^^^^^^^^^^^^ Inherit directly from Admin::BaseController.
      end
    RUBY
  end

  it "名前空間を掘るときは一つ上の基底クラスを継承する" do
    expect_no_offenses("class Admin::BaseController < ApplicationController; end", "app/controllers/admin/base_controller.rb")
    expect_no_offenses("class Admin::Reports::BaseController < Admin::BaseController; end", "app/controllers/admin/reports/base_controller.rb")
    expect_offense(<<~RUBY, "app/controllers/admin/reports/base_controller.rb")
      class Admin::Reports::BaseController < ApplicationController
                                             ^^^^^^^^^^^^^^^^^^^^^ Inherit directly from Admin::BaseController.
      end
    RUBY
  end

  it "名前空間の基底クラスを完全名とモジュール内の相対名で指定できる" do
    expect_no_offenses("class ProfilesController < ApplicationController; end", "app/controllers/profiles_controller.rb")
    expect_no_offenses("class Admin::Reports::OrdersController < ::Admin::Reports::BaseController; end", "app/controllers/admin/reports/orders_controller.rb")
    expect_no_offenses(<<~RUBY, "app/controllers/admin/bentos_controller.rb")
      module Admin
        class BentosController < BaseController
        end
      end
    RUBY
  end

  it "ルートの同名定数や別用途のDeviseコントローラを管理画面の親にできない" do
    expect_offense(<<~RUBY, "app/controllers/admin/bentos_controller.rb")
      module Admin
        class BentosController < ::BaseController
                                 ^^^^^^^^^^^^^^^^ Inherit directly from Admin::BaseController.
        end
      end
    RUBY
    expect_offense(<<~RUBY, "app/controllers/admin/bentos_controller.rb")
      class Admin::BentosController < Devise::SessionsController
                                      ^^^^^^^^^^^^^^^^^^^^^^^^^^ Inherit directly from Admin::BaseController.
      end
    RUBY
  end

  it "RailsとDeviseが提供する親は用途が決まったコントローラで使える" do
    expect_no_offenses("class ApplicationController < ActionController::Base; end", "app/controllers/application_controller.rb")
    expect_no_offenses("class HealthController < Rails::HealthController; end", "app/controllers/health_controller.rb")
    expect_no_offenses("class Admin::SessionsController < Devise::SessionsController; end", "app/controllers/admin/sessions_controller.rb")
  end
end
