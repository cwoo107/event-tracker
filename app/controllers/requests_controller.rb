class RequestsController < ApplicationController
  def index
    @requests = Event.unassigned.includes(:liaisons).order(created_at: :desc)
  end
end
