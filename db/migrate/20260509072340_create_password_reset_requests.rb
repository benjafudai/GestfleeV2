class CreatePasswordResetRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :password_reset_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :admin, null: true, foreign_key: { to_table: :users }
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
