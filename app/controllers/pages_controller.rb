class PagesController < ApplicationController
  allow_unauthenticated_access

  # GET / for signed-out visitors - signed-in users are sent straight to
  # the map, so this marketing page is only ever seen before sign in.
  def home
    redirect_to map_path if authenticated?
  end
end
