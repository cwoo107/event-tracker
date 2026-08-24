class AddDriveRouteGeometryToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :drive_route_geometry, :jsonb
  end
end
