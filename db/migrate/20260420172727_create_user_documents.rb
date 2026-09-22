class CreateUserDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :user_documents do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :doc_type, null: false
      t.date :due_on, null: false
      t.text :notes
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
