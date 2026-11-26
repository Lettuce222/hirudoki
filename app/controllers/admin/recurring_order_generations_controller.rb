class Admin::RecurringOrderGenerationsController < Admin::BaseController
  def new
    today = Date.current
    served_on = DailyMenu.order_window_open_for?(today) ? today : today.tomorrow
    @generation = RecurringOrderGeneration.new(served_on:)
  end

  def create
    @generation = RecurringOrderGeneration.new(recurring_order_generation_params)
    @generated = @generation.generate
    render :new, status: @generated ? :ok : :unprocessable_content
  end

  private

  def recurring_order_generation_params
    params.expect(recurring_order_generation: [ :served_on ])
  end
end
