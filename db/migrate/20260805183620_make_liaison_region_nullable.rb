class MakeLiaisonRegionNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :liaisons, :region, true
  end
end
