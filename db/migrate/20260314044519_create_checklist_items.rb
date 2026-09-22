class CreateChecklistItems < ActiveRecord::Migration[7.1]
  def change
    create_table :checklist_items do |t|
      t.references :checklist_template, null: false, foreign_key: true
      t.string :label, null: false
      t.integer :item_type, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.boolean :required, null: false, default: false

      t.timestamps
    end
  end
end
