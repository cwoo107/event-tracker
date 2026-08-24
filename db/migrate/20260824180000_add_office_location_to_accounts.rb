class AddOfficeLocationToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :office_address, :string
    add_column :accounts, :office_city, :string
    add_column :accounts, :office_state, :string, default: "CA"
    add_column :accounts, :office_zip, :string
    add_column :accounts, :office_location, :st_point, geographic: true, srid: 4326

    # The address every drive-time/distance figure was hard-coded to
    # measure from before this became a per-account setting (see
    # Event#refresh_drive_time!) - backfilled here so the existing
    # organization's map/drive-time behavior doesn't change.
    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE accounts
          SET office_address = '4005 Port Chicago Hwy',
              office_city = 'Concord',
              office_state = 'CA',
              office_zip = '94520',
              office_location = ST_SetSRID(ST_MakePoint(-122.0247, 38.0116), 4326)
          WHERE name = 'USAN'
        SQL
      end
    end
  end
end
