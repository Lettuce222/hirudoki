require "rails_helper"

RSpec.describe "Health", type: :request do
  it "checks database connectivity" do
    expect(ActiveRecord::Base.connection).to receive(:select_value).with("SELECT 1").and_call_original

    get rails_health_check_path

    expect(response).to have_http_status(:ok)
  end

  it "returns service unavailable when the database is unavailable" do
    allow(ActiveRecord::Base.connection).to receive(:select_value).with("SELECT 1").and_raise(ActiveRecord::ConnectionNotEstablished)

    get rails_health_check_path

    expect(response).to have_http_status(:service_unavailable)
  end
end
