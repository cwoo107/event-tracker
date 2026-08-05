class DashboardController < ApplicationController
  def index
    @report = DashboardReport.new(range: params[:range])
  end
end
