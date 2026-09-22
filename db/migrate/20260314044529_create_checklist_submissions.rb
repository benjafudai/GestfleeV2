class CreateChecklistSubmissions < ActiveRecord::Migration[7.1]
  def change
    create_table :checklist_submissions do |t|
      t.references :checklist_template, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :submitted_at
      t.integer :status, null: false, default: 0
      t.text :admin_notes

      t.timestamps
    end
  end
end
