class DashboardController < ApplicationController
  def index
    @report = DashboardReport.new(account: Current.account, range: params[:range])
  end
end
