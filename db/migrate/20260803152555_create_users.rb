class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.string :job_title
      # coordinator: department staff who intake/assign events but don't host them
      # liaison: staff who host events and can be assigned
      # admin: full access, manages settings/scoring weights
      t.integer :role, null: false, default: 0

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
