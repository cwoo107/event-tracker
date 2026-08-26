class AllowBlankRequesterFieldsOnEvents < ActiveRecord::Migration[8.1]
  def change
    change_column_null :events, :requester_name, true
    change_column_null :events, :requester_email, true
  end
end
