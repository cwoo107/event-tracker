class CalendarController < ApplicationController
  def index
    today = Date.current
    year = params[:year].presence&.to_i || today.year
    month = params[:month].presence&.to_i || today.month

    @calendar = CalendarMonth.new(account: Current.account, year: year, month: month)
    @liaisons = Current.account.liaisons.active.includes(:user).order(:region)
  end
end
