class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :message, null: false
      t.datetime :read_at
      t.references :notifiable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
