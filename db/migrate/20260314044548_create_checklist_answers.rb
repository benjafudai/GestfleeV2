class CreateChecklistAnswers < ActiveRecord::Migration[7.1]
  def change
    create_table :checklist_answers do |t|
      t.references :checklist_submission, null: false, foreign_key: true
      t.references :checklist_item, null: false, foreign_key: true
      t.text :value

      t.timestamps
    end
  end
end
