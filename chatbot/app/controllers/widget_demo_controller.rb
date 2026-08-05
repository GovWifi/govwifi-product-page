class WidgetDemoController < ApplicationController
  # Development-only page for exercising the widget without needing
  # to re-deploy product-page. Locked out in production.
  before_action :forbid_in_production

  def show; end

  private

  def forbid_in_production
    head :not_found if Rails.env.production?
  end
end
