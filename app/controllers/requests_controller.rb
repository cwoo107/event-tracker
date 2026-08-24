class RequestsController < ApplicationController
  def index
    @requests = Current.account.events.unassigned.includes(:liaisons).order(created_at: :desc)
  end
end
