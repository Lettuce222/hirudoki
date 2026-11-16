class HealthController < Rails::HealthController
  def show
    ActiveRecord::Base.connection.select_value("SELECT 1")
    super
  rescue ActiveRecord::ActiveRecordError
    render plain: "Service unavailable", status: :service_unavailable
  end
end
